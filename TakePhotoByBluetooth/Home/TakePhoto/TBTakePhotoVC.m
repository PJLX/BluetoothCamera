//
//  TBTakePhotoVC.m
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/23.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "TBTakePhotoVC.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "RMUniversalAlert.h"

#import "TBServiceManager.h"
#import <AVFoundation/AVFoundation.h>
#import <StoreKit/StoreKit.h>

@interface TBTakePhotoVC ()
<
CBPeripheralManagerDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
AVSpeechSynthesizerDelegate
>

/**
 UI
 */
@property (weak, nonatomic) IBOutlet UIView *view1;
@property (weak, nonatomic) IBOutlet UIView *view2;
@property (weak, nonatomic) IBOutlet UIView *view3;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;

@property (weak, nonatomic) IBOutlet UIView *takePhotoView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;

@property (weak, nonatomic) IBOutlet UIView *recordView;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;

@property (weak, nonatomic) IBOutlet UILabel *stateLabel;


/**
 imagePickerController
 */
@property (nonatomic, strong) UIImagePickerController *imagePickerController;

/**
 CBPeripheralManager
 */
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@property (nonatomic, strong) CBMutableService *cameraService;
@property (nonatomic, strong) CBMutableCharacteristic *takePhotoCharacteristic;
@property (nonatomic, strong) CBMutableCharacteristic *recordCharacteristic;

///文字转语音
@property (nonatomic, strong) AVSpeechSynthesizer *speechSynthesizer;

///定时器
@property (nonatomic, strong) NSTimer *waitTimer;


@end

@implementation TBTakePhotoVC

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

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

- (UIImagePickerController *)imagePickerController{
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc]init];
        _imagePickerController.delegate = self;
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    return _imagePickerController;
}

- (CBMutableCharacteristic *)takePhotoCharacteristic{
    if (!_takePhotoCharacteristic) {
        _takePhotoCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[TBServiceManager sharedInstance].takePhotoCharacteristicUUID
                                                                      properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead | CBCharacteristicPropertyNotifyEncryptionRequired
                                                                           value:nil
                                                                     permissions:CBAttributePermissionsReadEncryptionRequired | CBAttributePermissionsWriteEncryptionRequired];
    }
    return _takePhotoCharacteristic;
}

- (CBMutableCharacteristic *)recordCharacteristic{
    if (!_recordCharacteristic) {
        _recordCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[TBServiceManager sharedInstance].recordCharacteristicUUID
                                                                      properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead | CBCharacteristicPropertyNotifyEncryptionRequired
                                                                           value:nil
                                                                     permissions:CBAttributePermissionsReadEncryptionRequired | CBAttributePermissionsWriteEncryptionRequired];
    }
    return _recordCharacteristic;
}

- (CBMutableService *)cameraService{
    if (!_cameraService) {
        _cameraService = [[CBMutableService alloc] initWithType:[TBServiceManager sharedInstance].cameraServiceUUID primary:YES];
        _cameraService.characteristics = @[self.takePhotoCharacteristic, self.recordCharacteristic];
    }
    return _cameraService;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.takePhotoView.alpha = 0;
    self.recordView.alpha = 0;
    self.stateLabel.text = @"使用前请先确保蓝牙已经开启。点击发射按钮来发射信号以备另一台Apple设备识别";
}

#pragma mark - 返回
- (IBAction)leftBtnAction:(UIButton *)sender {
    if (self.peripheralManager.isAdvertising) {
        [self.peripheralManager stopAdvertising];
    }
    [self p_invalidateTimer];
    
    [super leftBtnAction];
}

#pragma mark - 发射
- (IBAction)startAction:(UIButton *)sender {
    //无法设置CBPeripheralManagerOptionRestoreIdentifierKey，会crash
//    switch ([CBPeripheralManager authorizationStatus]) {
//        case CBPeripheralManagerAuthorizationStatusNotDetermined:{
//
//        }
//            break;
//
//        case CBPeripheralManagerAuthorizationStatusRestricted:{
//
//        }
//            break;
//
//        case CBPeripheralManagerAuthorizationStatusDenied:{
//
//        }
//            break;
//
//        case CBPeripheralManagerAuthorizationStatusAuthorized:{
//
//        }
//            break;
//    }
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:dispatch_get_main_queue()
                                                                   options:@{CBPeripheralManagerOptionShowPowerAlertKey: @(YES)
                                                                             }];
}

#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
        case CBPeripheralManagerStateUnknown:
        {
            self.stateLabel.text = @"未知状态";
        }
            break;
            
        case CBPeripheralManagerStateResetting:
        {
            self.stateLabel.text = @"重置中...";
        }
            break;
            
        case CBPeripheralManagerStateUnsupported:
        {
            self.stateLabel.text = @"设备不支持蓝牙";
        }
            break;
            
        case CBPeripheralManagerStateUnauthorized:
        {
            self.stateLabel.text = @"还未授权使用Bluetooth";
        }
            break;
            
        case CBPeripheralManagerStatePoweredOff:
        {
            [self p_speakText:@"请打开蓝牙"];
            self.stateLabel.text = @"请打开蓝牙";
            [self.peripheralManager removeService:self.cameraService];
        }
            break;
            
        case CBPeripheralManagerStatePoweredOn:
        {
            [self p_speakText:@"开始添加服务"];
            self.stateLabel.text = @"手机蓝牙已经经打开,开始添加服务";
            
            self.startBtn.enabled = NO;

            //不可重复添加
            [self.peripheralManager addService:self.cameraService];

        }
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(nullable NSError *)error{
    if (!error) {
        self.stateLabel.text = [NSString stringWithFormat:@"添加服务成功，2S后开始发送数据"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.stateLabel.text = [NSString stringWithFormat:@"添加服务成功，1S后开始发送数据"];
        });
        [self.startBtn setTitle:@"准备发射" forState:UIControlStateNormal];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey: @"小叮当",
                                                       CBAdvertisementDataServiceUUIDsKey: @[self.cameraService.UUID]}];
        });
    } else {
        self.stateLabel.text = [NSString stringWithFormat:@"添加服务失败:%@",error.localizedDescription];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    if (!error) {
        self.stateLabel.text = @"数据发送成功,请等待控制设备连接";
        [self.startBtn setTitle:@"等待连接" forState:UIControlStateNormal];
        self.waitTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(p_waitAction:) userInfo:NULL repeats:YES];

    } else {
        self.stateLabel.text = [NSString stringWithFormat:@"数据发送失败:%@",error.localizedDescription];
        
        [self.peripheralManager removeService:self.cameraService];
        self.startBtn.enabled = YES;
        [self.startBtn setTitle:@"重新发送" forState:UIControlStateNormal];
    
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    printf("%s\n",__PRETTY_FUNCTION__);
    if ([characteristic.UUID isEqual:[TBServiceManager sharedInstance].takePhotoCharacteristicUUID] ||
        [characteristic.UUID isEqual:[TBServiceManager sharedInstance].recordCharacteristicUUID]) {//自己被主设连接上了
        
        [self p_speakText:@"连接成功"];
        [self.startBtn setTitle:@"等待..." forState:UIControlStateNormal];
        self.stateLabel.text = @"成功连接到控制设备\n请等待控制设备选择拍照/录像模式";
        
        [UIView animateWithDuration:1 animations:^{
            self.takePhotoView.alpha = 0.2;
            self.recordView.alpha = 0.2;
            self.startBtn.titleLabel.alpha = 1;
        }];
        
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    printf("%s\n",__PRETTY_FUNCTION__);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    printf("%s\n",__PRETTY_FUNCTION__);
    if ([request.characteristic.UUID isEqual:self.cameraService.UUID]) {
        
        if ([request.characteristic.UUID isEqual:self.takePhotoCharacteristic.UUID]) {
            if (request.offset > self.takePhotoCharacteristic.value.length) {
                [peripheral respondToRequest:request withResult:CBATTErrorInvalidOffset];
                return;
            }
            
            request.value = [self.takePhotoCharacteristic.value subdataWithRange:NSMakeRange(request.offset, self.takePhotoCharacteristic.value.length - request.offset)];
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        } else if ([request.characteristic.UUID isEqual:self.recordCharacteristic.UUID]) {
            if (request.offset > self.recordCharacteristic.value.length) {
                [peripheral respondToRequest:request withResult:CBATTErrorInvalidOffset];
                return;
            }
            
            request.value = [self.recordCharacteristic.value subdataWithRange:NSMakeRange(request.offset, self.recordCharacteristic.value.length - request.offset)];
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        }
        
    } else {
        [peripheral respondToRequest:request withResult:CBATTErrorInvalidHandle];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests{
    printf("%s\n",__PRETTY_FUNCTION__);
    for (CBATTRequest *ATTRequest in requests) {
        NSData *data = ATTRequest.value;
        if ([data isEqual:[TBServiceManager sharedInstance].prepareToTakePictureData]) {//拍照
            [self takePhotoAction:nil];
            
        }else if ([data isEqual:[TBServiceManager sharedInstance].takePictureData]) {
            self.stateLabel.text = @"接收到拍照指令，开始拍照";
            [self.imagePickerController takePicture];
            
            BOOL sended = [self.peripheralManager updateValue:[TBServiceManager sharedInstance].takePictureOverData forCharacteristic:self.takePhotoCharacteristic onSubscribedCentrals:nil];
            if (sended) {
                self.stateLabel.text = @"成功通知控制设备拍照完成";
            }
        } else if ([data isEqual:[TBServiceManager sharedInstance].prepareToRecordData]) {//录像
            [self recordAction:nil];
            
        } else if ([data isEqual:[TBServiceManager sharedInstance].recordStartData]) {
            self.stateLabel.text = @"接收到录像指令，开始录像";
            [self.imagePickerController startVideoCapture];
            
            BOOL sended = [self.peripheralManager updateValue:[TBServiceManager sharedInstance].recordingData forCharacteristic:self.recordCharacteristic onSubscribedCentrals:nil];
            
            if (sended) {
                self.stateLabel.text = @"成功通知控制设备开始录像";
            }
            
        } else if ([data isEqual:[TBServiceManager sharedInstance].recordEndData]) {
            self.stateLabel.text = @"接收到结束录像指令";
            [self.imagePickerController stopVideoCapture];
            
            BOOL sended = [self.peripheralManager updateValue:[TBServiceManager sharedInstance].recordOverData forCharacteristic:self.recordCharacteristic onSubscribedCentrals:nil];
            if (sended) {
                self.stateLabel.text = @"成功通知控制设备结束录像";
            }
        }
    }
    
    [peripheral respondToRequest:requests.firstObject withResult:CBATTErrorSuccess];
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    printf("%s\n",__PRETTY_FUNCTION__);
}

#pragma mark - 拍照
- (IBAction)takePhotoAction:(UIButton *)sender {
    self.imagePickerController.mediaTypes = @[(NSString *) kUTTypeImage];
    [self.navigationController presentViewController:self.imagePickerController animated:YES completion:^{
        
    }];
    
    BOOL sended = [self.peripheralManager updateValue:[TBServiceManager sharedInstance].takePictureReadyData forCharacteristic:self.takePhotoCharacteristic onSubscribedCentrals:nil];
    if (sended) {
        self.stateLabel.text = @"等待控制设备拍照";
    } else {
    }
}

#pragma mark - 录像
- (IBAction)recordAction:(UIButton *)sender {
    self.imagePickerController.mediaTypes = @[(NSString *) kUTTypeMovie];
    [self.navigationController presentViewController:self.imagePickerController animated:YES completion:^{
        
    }];
    
    BOOL sended = [self.peripheralManager updateValue:[TBServiceManager sharedInstance].recordReadyData forCharacteristic:self.recordCharacteristic onSubscribedCentrals:nil];
    if (sended) {
        self.stateLabel.text = @"等待控制设备录像";
    } else {
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    BOOL b = [picker.mediaTypes containsObject:(NSString *) kUTTypeImage];
    BOOL sended = [self.peripheralManager updateValue:[TBServiceManager sharedInstance].cameraUnReadyData
                                    forCharacteristic:b ? self.takePhotoCharacteristic : self.recordCharacteristic
                                 onSubscribedCentrals:nil];
    if (sended) {
        self.stateLabel.text = @"请等待控制设备选择拍照/录像模式";
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSLog(@"info:\n%@", info);
    
    NSDictionary *metaData = [info valueForKey:UIImagePickerControllerMediaMetadata];
    NSLog(@"mediaData:\n%@", metaData);
    
    NSString *mediaType = [info valueForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *) kUTTypeImage]) {
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        
    } else {
        NSURL *url  = [info valueForKey:UIImagePickerControllerMediaURL];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)) {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        } else {
            self.stateLabel.text = @"无法保存到相册";
        }
    }
    
    BOOL b = [picker.mediaTypes containsObject:(NSString *) kUTTypeImage];
    BOOL sended = [self.peripheralManager updateValue:[TBServiceManager sharedInstance].cameraUnReadyData
                                    forCharacteristic:b ? self.takePhotoCharacteristic : self.recordCharacteristic
                                 onSubscribedCentrals:nil];
    if (sended) {
        self.stateLabel.text = @"请等待控制设备选择拍照/录像模式";
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (!error) {
        self.stateLabel.text = @"保存成功";
        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
    } else {
        self.stateLabel.text = @"保存失败";
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (!error) {
        self.stateLabel.text = @"保存成功";
        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
    } else {
        self.stateLabel.text = @"保存失败";
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

- (void)p_waitAction:(NSTimer *)timer{
    if (self.startBtn.titleLabel.alpha == 1) {
        [UIView animateWithDuration:1 animations:^{
            self.startBtn.titleLabel.alpha = 0;
        }];
    } else {
        [UIView animateWithDuration:1 animations:^{
            self.startBtn.titleLabel.alpha = 1;
        }];
    }
}

- (void)p_invalidateTimer{
    if (self.waitTimer) {
        [self.waitTimer invalidate];
        self.waitTimer = nil;
    }
}

@end
