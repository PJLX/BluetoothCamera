//
//  TBBaseVC.m
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/24.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "TBBaseVC.h"

@interface TBBaseVC ()

@end

@implementation TBBaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)leftBtnAction{
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
