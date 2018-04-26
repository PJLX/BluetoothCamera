//
//  TBContrlolVC.m
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/23.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "TBContrlolVC.h"

#import "TBPeripheralListVC.h"

#import "TBServiceManager.h"
#import <AVFoundation/AVFoundation.h>
#import <StoreKit/StoreKit.h>

@interface TBContrlolVC ()
<
CBCentralManagerDelegate,
CBPeripheralDelegate,
AVSpeechSynthesizerDelegate
>

/**
 UI
 */
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UIView *view1;
@property (weak, nonatomic) IBOutlet UIView *view2;
@property (weak, nonatomic) IBOutlet UIView *view3;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;

@property (weak, nonatomic) IBOutlet UILabel *stateLabel;

@property (weak, nonatomic) IBOutlet UIView *takePhotoView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *takePhotoViewLeading;

@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (weak, nonatomic) IBOutlet UILabel *takePhotoLabel;

@property (weak, nonatomic) IBOutlet UIView *recordView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recordViewTrailing;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UILabel *recordLabel;

@property (nonatomic, strong) TBPeripheralListVC *peripheralListVC;


/**
 BLE
 */
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristicTakePhoto;
@property (nonatomic, strong) CBCharacteristic *characteristicRecord;


/**
 Data
 */
@property (nonatomic, strong) NSMutableArray *peripheralList;

@property (nonatomic, assign) BOOL isPeripheralReadyForTakePhoto;

@property (nonatomic, assign) BOOL isPeripheralReadyForRecord;

@property (nonatomic, strong) NSTimer *searchTimer;


///文字转语音
@property (nonatomic, strong) AVSpeechSynthesizer *speechSynthesizer;

@end

@implementation TBContrlolVC

- (void)dealloc{
    printf("%s\n",__PRETTY_FUNCTION__);
}

#pragma mark - lazy
- (AVSpeechSynthesizer *)speechSynthesizer{
    if (!_speechSynthesizer) {
        _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
        _speechSynthesizer.delegate = self;
    }
    return _speechSynthesizer;
}

- (NSMutableArray *)peripheralList{
    if (!_peripheralList) {
        _peripheralList = [NSMutableArray new];
    }
    return _peripheralList;
}

- (TBPeripheralListVC *)peripheralListVC{
    if (!_peripheralListVC) {
        __weak TBContrlolVC *weakSelf = self;
        _peripheralListVC = [TBPeripheralListVC loadWithPeripheralList:self.peripheralList];
        __weak TBPeripheralListVC *weakPeripheralListVC = _peripheralListVC;

        [_peripheralListVC setDidSelectDevice:^(NSString *deviceName){
            for (CBPeripheral *peripheral in weakSelf.peripheralList) {
                if ([peripheral.name isEqualToString:deviceName]) {
                    weakSelf.peripheral = peripheral;
                    weakSelf.peripheral.delegate = weakSelf;
                    [weakSelf.centralManager connectPeripheral:peripheral
                                                   options:@{CBConnectPeripheralOptionNotifyOnConnectionKey: @(YES),
                                                             CBConnectPeripheralOptionNotifyOnDisconnectionKey: @(YES),
                                                             CBConnectPeripheralOptionNotifyOnNotificationKey: @(YES)}];
                    [weakSelf.centralManager stopScan];
                    [weakPeripheralListVC dismissViewControllerAnimated:YES completion:^{
                        
                    }];
                    break;
                }
            }
        }];
        
        [_peripheralListVC setCancel:^{
            [weakSelf.centralManager stopScan];
            [weakSelf.activityIndicatorView stopAnimating];
            weakSelf.activityIndicatorView.hidden = YES;
            weakSelf.connectBtn.enabled = YES;
            [weakSelf.connectBtn setTitle:@"继续搜索" forState:UIControlStateNormal];
            weakSelf.stateLabel.text = @"如果未找到对应的设备，可以尝试继续搜索";
            
            [weakPeripheralListVC dismissViewControllerAnimated:YES completion:^{
                
            }];
        }];
        
        [self p_invalidateTimer];
        self.connectBtn.titleLabel.alpha = 1;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(p_searchFailed) object:nil];
    }
    return _peripheralListVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.activityIndicatorView.hidden = YES;
    self.takePhotoView.alpha = 0;
    self.recordView.alpha = 0;
    
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - 返回
- (IBAction)leftBtnAction {
    if (self.centralManager.isScanning) {
        [self.centralManager stopScan];
    }
    
    self.centralManager.delegate = nil;
    self.centralManager = nil;
    [self p_invalidateTimer];
    
    [super leftBtnAction];
}

#pragma mark - 搜索
- (IBAction)connectAction:(UIButton *)sender {
    [self.peripheralList removeAllObjects];
    self.peripheral = nil;
    self.characteristicTakePhoto = nil;
    _peripheralListVC = nil;
    self.takePhotoView.alpha = 0;
    self.recordView.alpha = 0;
    self.connectBtn.enabled = NO;

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:dispatch_get_main_queue()
                                                             options:@{CBCentralManagerOptionShowPowerAlertKey: @(YES)}];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:{
            self.stateLabel.text = @"未知状态";
            break;
        }
            
        case CBCentralManagerStateResetting:{
            self.stateLabel.text = @"重置中...";
            break;
        }
            
        case CBCentralManagerStateUnsupported:{
            self.stateLabel.text = @"设备不支持Bluetooth";
            break;
        }
            
        case CBCentralManagerStateUnauthorized:{
            self.stateLabel.text = @"还未授权使用Bluetooth";
            break;
        }
            
        case CBCentralManagerStatePoweredOff:{
            self.stateLabel.text = @"请打开蓝牙";
            [self p_speakText:@"请打开蓝牙"];
            break;
        }
            
        case CBCentralManagerStatePoweredOn:{
            [self p_speakText:@"开始搜索iPhone"];
            self.stateLabel.text = @"开始搜索iPhone";
            self.activityIndicatorView.hidden = NO;
            [self.activityIndicatorView startAnimating];
            [central scanForPeripheralsWithServices:@[[TBServiceManager sharedInstance].cameraServiceUUID]
                                            options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(NO),
                                                      CBConnectPeripheralOptionNotifyOnConnectionKey: @(YES)
                                                      }
             ];
            [self.connectBtn setTitle:@"搜索中..." forState:UIControlStateNormal];
            self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(p_searchAction:) userInfo:NULL repeats:YES];
            
            //超时
            [self performSelector:@selector(p_searchFailed) withObject:nil afterDelay:10];
            
            break;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    if (peripheral.name != nil) {
        [self.peripheralList addObject:peripheral];
        [self.peripheralListVC reloadData:self.peripheralList];
        
        if (!self.peripheralListVC.presentingViewController) {
            [self presentViewController:self.peripheralListVC animated:YES completion:^{
                
            }];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    [self.centralManager stopScan];
    //搜索服务
    [peripheral discoverServices:@[[TBServiceManager sharedInstance].cameraServiceUUID]];
    
    //UI
    [self p_speakText:@"连接成功"];
    self.stateLabel.text = [NSString stringWithFormat:@"与%@连接成功\n请选择拍照/录像",peripheral.name];
    [self.activityIndicatorView stopAnimating];
    self.activityIndicatorView.hidden = YES;
    
    [UIView animateWithDuration:1 animations:^{
        self.view1.alpha = 0;
        self.view2.alpha = 0;
        self.view3.alpha = 0;
        self.connectBtn.alpha = 0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 animations:^{
            self.takePhotoView.alpha = 1;
            self.recordView.alpha = 1;
        }];
    }];
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self p_speakText:@"连接失败"];
    self.stateLabel.text = [NSString stringWithFormat:@"连接设备：(%@)失败",peripheral.name];
    self.connectBtn.enabled = YES;
    [self.connectBtn setTitle:@"重新搜索" forState:UIControlStateNormal];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    self.stateLabel.text = [NSString stringWithFormat:@"已断开与%@的连接",peripheral.name];
    
    [UIView animateWithDuration:1 animations:^{
        self.view1.alpha = 1;
        self.view2.alpha = 1;
        self.view3.alpha = 1;
        self.connectBtn.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    self.connectBtn.enabled = YES;
    [self.connectBtn setTitle:@"重新搜索" forState:UIControlStateNormal];
    self.takePhotoView.alpha = 0;
    self.takePhotoViewLeading.constant = 30;
    self.recordView.alpha = 0;
    self.recordViewTrailing.constant = 30;
    self.isPeripheralReadyForTakePhoto = NO;
    self.isPeripheralReadyForRecord = NO;

}

#pragma mark - CBPeripheralDelegate
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
    if (!error) {
        for (int i = 0; i < peripheral.services.count; i++) {
            CBService *service = peripheral.services[i];
            NSLog(@"service:%@",service.UUID);
            if ([service.UUID isEqual:[TBServiceManager sharedInstance].cameraServiceUUID]) {
                [peripheral discoverCharacteristics:@[[TBServiceManager sharedInstance].takePhotoCharacteristicUUID,
                                                      [TBServiceManager sharedInstance].recordCharacteristicUUID]
                                         forService:service
                 ];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
    if (!error) {
        for(int i=0; i < service.characteristics.count; i++) {
            
            CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
            NSLog(@"UUID:%@",characteristic.UUID);
            
            if ([characteristic.UUID isEqual:[TBServiceManager sharedInstance].takePhotoCharacteristicUUID]) {
                self.characteristicTakePhoto = characteristic;
                
                //外设可通过代理方法：订阅了通知，来判断自己被主设连接上了
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            if ([characteristic.UUID isEqual:[TBServiceManager sharedInstance].recordCharacteristicUUID]) {
                self.characteristicRecord = characteristic;
                
                //外设可通过代理方法：订阅了通知，来判断自己被主设连接上了
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
    if (!error) {
        if ([characteristic.UUID isEqual:[TBServiceManager sharedInstance].takePhotoCharacteristicUUID]) {//拍照
            
            if ([characteristic.value isEqualToData:[TBServiceManager sharedInstance].takePictureOverData]) {//拍照完成
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self) {
                        [self p_speakText:@"恭喜,拍照成功"];
                        self.stateLabel.text = [NSString stringWithFormat:@"恭喜💐,拍照成功,请在%@上查看照片\n点击“使用照片”会保存到相册\n或者重拍",self.peripheral.name];

                        ///评价
                        NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:kTakePhotosCounts];
                        [[NSUserDefaults standardUserDefaults] setInteger: count+1 forKey:kTakePhotosCounts];
                        if ((count+1)%10 == 0) {
                            if ([UIDevice currentDevice].systemVersion.floatValue >= 10.3) {
                                [SKStoreReviewController requestReview];
                            }
                        }
                    }
                });
            } else if ([characteristic.value isEqualToData:[TBServiceManager sharedInstance].cameraUnReadyData]) {
                self.isPeripheralReadyForTakePhoto = NO;
                self.takePhotoLabel.text = @"准备拍照";
                self.stateLabel.text = [NSString stringWithFormat:@"%@等待进入拍照状态...",self.peripheral.name];
            } else if ([characteristic.value isEqualToData:[TBServiceManager sharedInstance].takePictureReadyData]) {
                self.isPeripheralReadyForTakePhoto = YES;
                self.takePhotoLabel.text = @"拍照";
                self.stateLabel.text = [NSString stringWithFormat:@"%@已经进入拍照状态，可以拍照",self.peripheral.name];
                
                if (self.recordView.alpha == 1) {
                    [UIView animateWithDuration:0.5 animations:^{
                        self.takePhotoViewLeading.constant = (LXScreenWidth - self.takePhotoView.width)/2;
                        self.recordView.alpha = 0;
                        [self.view layoutIfNeeded];
                    }];
                }
            }
            
        } else if ([characteristic.UUID isEqual:[TBServiceManager sharedInstance].recordCharacteristicUUID]) {//录像
            if ([characteristic.value isEqualToData:[TBServiceManager sharedInstance].recordOverData]) {//录像完成
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self) {
                        [self p_speakText:@"恭喜,录像成功"];
                        self.stateLabel.text = [NSString stringWithFormat:@"恭喜💐,录像成功,请在%@上查看\n点击“使用视频”会保存到相册\n或者重拍",self.peripheral.name];

                        ///评价
                        NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:kTakeVideoCounts];
                        [[NSUserDefaults standardUserDefaults] setInteger: count+1 forKey:kTakeVideoCounts];
                        if ((count+1)%2 == 0) {
                            if ([UIDevice currentDevice].systemVersion.floatValue >= 10.3) {
                                [SKStoreReviewController requestReview];
                            }
                        }
                    }
                });
            } else if ([characteristic.value isEqualToData:[TBServiceManager sharedInstance].cameraUnReadyData]) {
                self.isPeripheralReadyForRecord = NO;
                self.recordLabel.text = @"准备录像";
                self.stateLabel.text = [NSString stringWithFormat:@"%@等待进入录像状态...",self.peripheral.name];
            } else if ([characteristic.value isEqualToData:[TBServiceManager sharedInstance].recordReadyData]) {
                self.isPeripheralReadyForRecord = YES;
                self.recordLabel.text = @"开始录制";
                self.stateLabel.text = [NSString stringWithFormat:@"%@已经进入录像状态，可以录像",self.peripheral.name];
                
                if (self.takePhotoView.alpha == 1) {
                    [UIView animateWithDuration:0.5 animations:^{
                        self.recordViewTrailing.constant = (LXScreenWidth - self.takePhotoView.width)/2;
                        self.takePhotoView.alpha = 0;
                        [self.view layoutIfNeeded];
                    }];
                }
            }
        }
    } else {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
    if (!error) {
        
        if ([characteristic.UUID isEqual:[TBServiceManager sharedInstance].cameraServiceUUID]) {
            
        }
        
    } else {
        self.stateLabel.text = [NSString stringWithFormat:@"拍照指令发送失败\n%@",error.localizedDescription];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    printf("%s\n",__PRETTY_FUNCTION__);
}

#pragma mark - 拍照
- (IBAction)takePhotoAction:(UIButton *)sender {
    if (!self.isPeripheralReadyForTakePhoto) {
        if (self.characteristicTakePhoto) {
            [self.peripheral writeValue:[TBServiceManager sharedInstance].prepareToTakePictureData
                      forCharacteristic:self.characteristicTakePhoto
                                   type:CBCharacteristicWriteWithResponse];
        }
    } else {
        if (self.characteristicTakePhoto) {
            [self.peripheral writeValue:[TBServiceManager sharedInstance].takePictureData
                      forCharacteristic:self.characteristicTakePhoto
                                   type:CBCharacteristicWriteWithResponse];
        }
    }
}

#pragma mark - 视频
- (IBAction)recordAction:(UIButton *)sender {
    if (!self.isPeripheralReadyForRecord) {
        if (self.characteristicRecord) {
            [self.peripheral writeValue:[TBServiceManager sharedInstance].prepareToRecordData
                      forCharacteristic:self.characteristicRecord
                                   type:CBCharacteristicWriteWithResponse];
        }
    } else {
        self.stateLabel.text = @"录制中...";
        if (self.characteristicRecord) {
            if (sender.selected == NO) {
                sender.selected = YES;
                self.recordLabel.text = @"结束录制";
                [self.peripheral writeValue:[TBServiceManager sharedInstance].recordStartData forCharacteristic:self.characteristicRecord type:CBCharacteristicWriteWithResponse];
                
            } else if (sender.selected == YES) {
                sender.selected = NO;
                self.recordLabel.text = @"开始录制";
                [self.peripheral writeValue:[TBServiceManager sharedInstance].recordEndData forCharacteristic:self.characteristicRecord type:CBCharacteristicWriteWithResponse];
            }
        }
    }
}

#pragma mark - AVSpeechSynthesizerDelegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
    
}

#pragma mark - private
- (void)p_speakText:(NSString *)text{
    AVSpeechUtterance *speechUtterance = [AVSpeechUtterance speechUtteranceWithString:text];
    [self.speechSynthesizer speakUtterance:speechUtterance];
}

- (void)p_searchAction:(NSTimer *)timer{
    if (self.connectBtn.titleLabel.alpha == 1) {
        [UIView animateWithDuration:1 animations:^{
            self.connectBtn.titleLabel.alpha = 0;
        }];
    } else {
        [UIView animateWithDuration:1 animations:^{
            self.connectBtn.titleLabel.alpha = 1;
        }];
    }
}

- (void)p_searchFailed{
    if (self) {
        [self p_invalidateTimer];
        self.connectBtn.titleLabel.alpha = 1;
        if (!self.peripheral) {
            [self.centralManager stopScan];
            
            self.connectBtn.enabled = YES;
            [self.activityIndicatorView stopAnimating];
            self.activityIndicatorView.hidden = YES;
            [self.connectBtn setTitle:@"继续搜索" forState:UIControlStateNormal];
            self.stateLabel.text = @"🙄...未搜索到相应iPhone";
            [self p_speakText:@"抱歉，未搜索到相应iPhone"];
        }
    }
}

- (void)p_invalidateTimer{
    if (self.searchTimer) {
        [self.searchTimer invalidate];
        self.searchTimer = nil;
    }
}

@end
