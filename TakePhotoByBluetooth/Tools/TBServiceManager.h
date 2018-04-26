//
//  TBServiceManager.h
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/24.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

/**
 提供全局蓝牙服务
 A:控制设备，B:相机设备. A控制B拍照/录像
 */
@interface TBServiceManager : NSObject

#pragma mark - sharedInstance
+ (instancetype)sharedInstance;

#pragma mark - NSData

/**
 B->A发射的拍照准备完成指令,B进入到拍照界面
 */
@property (nonatomic, strong) NSData *takePictureReadyData;

/**
 B->A发射的拍照取消/未准备完成指令,B退出拍照界面
 */
@property (nonatomic, strong) NSData *cameraUnReadyData;

/**
 A->B发射的指示B进入拍照界面的指令
 */
@property (nonatomic, strong) NSData *prepareToTakePictureData;

/**
 A->B发射的拍照指令
 */
@property (nonatomic, strong) NSData *takePictureData;

/**
 B->A发射的拍照完成指令,B此时等待用户选择保存照片或者重拍
 */
@property (nonatomic, strong) NSData *takePictureOverData;



/**
 B->A发射的录像准备完成指令,B进入到录像界面
 */
@property (nonatomic, strong) NSData *recordReadyData;

/**
 A->B发射的指示B进入录像界面指令
 */
@property (nonatomic, strong) NSData *prepareToRecordData;

/**
 A->B发射的开始录像指令
 */
@property (nonatomic, strong) NSData *recordStartData;

/**
 A->B发射的结束录像指令
 */
@property (nonatomic, strong) NSData *recordEndData;

/**
 B->A发射的开始录像指令,B此时正在录像
 */
@property (nonatomic, strong) NSData *recordingData;

/**
 B->A发射的录像完成指令,B此时等待用户选择保存视频或者重拍、编辑
 */
@property (nonatomic, strong) NSData *recordOverData;


#pragma mark - CBUUID

/**
 B->A发射的相机服务UUID
 */
@property (nonatomic, strong) CBUUID *cameraServiceUUID;

/**
 B->A发射的拍照特征UUID
 */
@property (nonatomic, strong) CBUUID *takePhotoCharacteristicUUID;

/**
 B->A发射的录像特征UUID
 */
@property (nonatomic, strong) CBUUID *recordCharacteristicUUID;

@end
