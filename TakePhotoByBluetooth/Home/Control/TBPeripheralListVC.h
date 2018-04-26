//
//  TBPeripheralListVC.h
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/23.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "TBBaseVC.h"

@interface TBPeripheralListVC : TBBaseVC

+ (instancetype)loadWithPeripheralList:(NSArray *)peripheralList;

- (void)reloadData:(NSArray *)peripheralList;

@property (nonatomic, copy) void (^didSelectDevice)(NSString *deviceName);

@property (nonatomic, copy) void (^cancel)(void);

@end
