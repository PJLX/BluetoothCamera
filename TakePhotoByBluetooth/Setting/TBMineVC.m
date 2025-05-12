//
//  TBMineVC.m
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/24.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "TBMineVC.h"

#import "TBGuideVC.h"

#import "BETableViewCellBackgroundView.h"

#import <SDWebImage/SDImageCache.h>
#import <MessageUI/MessageUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <StoreKit/StoreKit.h>

static NSString *kHeadImageKey = @"kHeadImageKey";

@interface TBMineVC ()

<
MFMessageComposeViewControllerDelegate,
MFMailComposeViewControllerDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
SKStoreProductViewControllerDelegate
>

/**
 UI
 */

@property (weak, nonatomic) IBOutlet BETableViewCellBackgroundView *headView;
@property (weak, nonatomic) IBOutlet UIImageView *headImg;

@property (weak, nonatomic) IBOutlet BETableViewCellBackgroundView *guideView;
@property (weak, nonatomic) IBOutlet BETableViewCellBackgroundView *downLoadView;

@property (weak, nonatomic) IBOutlet BETableViewCellBackgroundView *feedBackView;

@property (weak, nonatomic) IBOutlet BETableViewCellBackgroundView *evaluateView;


/**
 Data
 */

@end

@implementation TBMineVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = NO;

    WEAKSELF
    
    //头像
    self.headImg.layer.cornerRadius = CGRectGetWidth(self.headImg.frame)/2;
    self.headImg.layer.masksToBounds = YES;
    [self.headView setTouchEnd:^{
        [weakSelf pickImage];
    }];
    
    //引导
    [self.guideView setTouchEnd:^{
        TBGuideVC *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TBGuideVC"];
        [weakSelf.navigationController pushViewController:vc animated:YES];
    }];
    
    //反馈
    [self.feedBackView setTouchEnd:^{
        [RMUniversalAlert showActionSheetInViewController:self
                                                withTitle:nil
                                                  message:@"反馈问题"
                                        cancelButtonTitle:@"取消"
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:@[@"短信", @"邮件"]
                       popoverPresentationControllerBlock:^(RMPopoverPresentationController * _Nonnull popover) {
                           
                       } tapBlock:^(RMUniversalAlert * _Nonnull alert, NSInteger buttonIndex) {
                           if (buttonIndex == 2) {
                               [weakSelf message];
                           }
                           
                           if (buttonIndex == 3) {
                               [weakSelf mail];
                           }
                       }];
    }];
    
    //评价
    [self.evaluateView setTouchEnd:^{
        [SKStoreReviewController requestReview];
    }];
    
    //下载
    [self.downLoadView setTouchEnd:^{
        SKStoreProductViewController *vc = [[SKStoreProductViewController alloc] init];
        vc.delegate = weakSelf;
        [vc loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @(1243998293)} completionBlock:^(BOOL result, NSError * _Nullable error) {
        }];
        [weakSelf presentViewController:vc animated:YES completion:^{
        }];
    }];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    UIImage *img = [[SDImageCache sharedImageCache] imageFromCacheForKey:kHeadImageKey];
    if (img) {
        self.headImg.image = img;
    }
}

#pragma mark - UIImagePickerController
- (void)pickImage{
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController.delegate = self;
    
    [RMUniversalAlert showActionSheetInViewController:self
                                            withTitle:nil
                                              message:@"请选择"
                                    cancelButtonTitle:@"取消"
                               destructiveButtonTitle:nil
                                    otherButtonTitles:@[@"相机", @"相册"]
                   popoverPresentationControllerBlock:^(RMPopoverPresentationController * _Nonnull popover) {
                       
                   } tapBlock:^(RMUniversalAlert * _Nonnull alert, NSInteger buttonIndex) {
                       if (buttonIndex == 2) {
                           imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                           imagePickerController.allowsEditing = YES;
                           
                           [self.navigationController presentViewController:imagePickerController animated:YES completion:^{
                               
                           }];
                       }
                       
                       if (buttonIndex == 3) {
                           imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                           imagePickerController.allowsEditing = NO;
                           [self.navigationController presentViewController:imagePickerController animated:YES completion:^{
                               
                           }];
                       }
                   }];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
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
        self.headImg.image = image;
        
        [[SDImageCache sharedImageCache] storeImage:image forKey:kHeadImageKey completion:^{
            
        }];
        
        [picker dismissViewControllerAnimated:YES completion:nil];
        
    } else {
        
        
    }
}

#pragma mark - UIVideoEditorControllerDelegate
- (void)videoEditorControllerDidCancel:(UIVideoEditorController *)editor{
    [editor dismissViewControllerAnimated:YES completion:nil];
}

- (void)videoEditorController:(UIVideoEditorController *)editor didFailWithError:(NSError *)error{
    [editor dismissViewControllerAnimated:YES completion:nil];
}

- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath{
    NSLog(@"editedVideoPath:%@",editedVideoPath);
    
    [editor dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - message
- (void)message {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController* composeVC = [[MFMessageComposeViewController alloc] init];
        composeVC.messageComposeDelegate = self;
        composeVC.recipients = @[@"15001239548"];
        
        [self presentViewController:composeVC animated:YES completion:^{
            
        }];
        
    } else {
        NSLog(@"不支持发送短信");
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"sms:"]];
    }
}

#pragma mark - MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    NSLog(@"%@", @(result));
    switch (result) {
        case MessageComposeResultCancelled:
        {
            [SVProgressHUD showErrorWithStatus:@"取消发送"];
        }
            break;
            
        case MessageComposeResultSent:
        {
            [SVProgressHUD showErrorWithStatus:@"已发送"];
        }
            break;
            
        case MessageComposeResultFailed:
        {
            [SVProgressHUD showErrorWithStatus:@"发送失败"];
        }
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - mail
- (void)mail {
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
        composeVC.mailComposeDelegate = self;
        
        [composeVC setToRecipients:@[@"601148234@qq.com"]];
        [composeVC setSubject:@"反馈"];
        
        [self presentViewController:composeVC animated:YES completion:nil];
        
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:"]];
    }
    
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    NSLog(@"%@", @(result));
    switch (result) {
        case MFMailComposeResultCancelled:
        {
            [SVProgressHUD showErrorWithStatus:@"取消发送"];
        }
            break;
            
        case MFMailComposeResultSaved:
        {
            [SVProgressHUD showErrorWithStatus:@"草稿已保存"];
        }
            break;
            
        case MFMailComposeResultSent:
        {
            [SVProgressHUD showErrorWithStatus:@"已发送"];
        }
            break;
            
        case MFMailComposeResultFailed:
        {
            [SVProgressHUD showErrorWithStatus:@"发送失败"];
        }
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController __TVOS_PROHIBITED NS_AVAILABLE_IOS(6_0){
    [viewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
