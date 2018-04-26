//
//  TBServiceManager.m
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/24.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "TBServiceManager.h"

@interface TBServiceManager ()

@end

@implementation TBServiceManager

+ (instancetype)sharedInstance{
    
    static dispatch_once_t onceToken;
    static TBServiceManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [TBServiceManager new];
    });
    return manager;
}

#pragma mark - NSData-picture
- (NSData *)takePictureReadyData{
    if (!_takePictureReadyData) {
        Byte dataArr[2];
        dataArr[0]=0x01; dataArr[1]=0x01;
        _takePictureReadyData = [NSData dataWithBytes:dataArr length:2];
    }
    return _takePictureReadyData;
}

- (NSData *)cameraUnReadyData{
    if (!_cameraUnReadyData) {
        Byte dataArr[2];
        dataArr[0]=0x01; dataArr[1]=0x02;
        _cameraUnReadyData = [NSData dataWithBytes:dataArr length:2];
    }
    return _cameraUnReadyData;
}

- (NSData *)prepareToTakePictureData{
    if (!_prepareToTakePictureData) {
        Byte dataArr[2];
        dataArr[0]=0x01; dataArr[1]=0x03;
        _prepareToTakePictureData = [NSData dataWithBytes:dataArr length:2];
    }
    return _prepareToTakePictureData;
}

- (NSData *)takePictureData{
    if (!_takePictureData) {
        Byte dataArr[2];
        dataArr[0]=0x01; dataArr[1]=0x04;
        _takePictureData = [NSData dataWithBytes:dataArr length:2];
    }
    return _takePictureData;
}

- (NSData *)takePictureOverData{
    if (!_takePictureOverData) {
        Byte dataArr[2];
        dataArr[0]=0x01; dataArr[1]=0x05;
        _takePictureOverData = [NSData dataWithBytes:dataArr length:2];
    }
    return _takePictureOverData;
}

#pragma mark - NSData-video
- (NSData *)recordReadyData{
    if (!_recordReadyData) {
        Byte dataArr[2];
        dataArr[0]=0x02; dataArr[1]=0x01;
        _recordReadyData = [NSData dataWithBytes:dataArr length:2];
    }
    return _recordReadyData;
}

- (NSData *)prepareToRecordData{
    if (!_prepareToRecordData) {
        Byte dataArr[2];
        dataArr[0]=0x02; dataArr[1]=0x02;
        _prepareToRecordData = [NSData dataWithBytes:dataArr length:2];
    }
    return _prepareToRecordData;
}

- (NSData *)recordStartData{
    if (!_recordStartData) {
        Byte dataArr[2];
        dataArr[0]=0x02; dataArr[1]=0x03;
        _recordStartData = [NSData dataWithBytes:dataArr length:2];
    }
    return _recordStartData;
}

- (NSData *)recordEndData{
    if (!_recordEndData) {
        Byte dataArr[2];
        dataArr[0]=0x02; dataArr[1]=0x04;
        _recordEndData = [NSData dataWithBytes:dataArr length:2];
    }
    return _recordEndData;
}

- (NSData *)recordingData{
    if (!_recordingData) {
        Byte dataArr[2];
        dataArr[0]=0x02; dataArr[1]=0x05;
        _recordingData = [NSData dataWithBytes:dataArr length:2];
    }
    return _recordingData;
}

- (NSData *)recordOverData{
    if (!_recordOverData) {
        Byte dataArr[2];
        dataArr[0]=0x02; dataArr[1]=0x06;
        _recordOverData = [NSData dataWithBytes:dataArr length:2];
    }
    return _recordOverData;
}

#pragma mark - CBUUID
- (CBUUID *)cameraServiceUUID{
    if (!_cameraServiceUUID) {
        _cameraServiceUUID = [CBUUID UUIDWithString:@"AFE4BF39-9D58-4747-A321-F249EABF22E8"];
    }
    return _cameraServiceUUID;
}

- (CBUUID *)takePhotoCharacteristicUUID{
    if (!_takePhotoCharacteristicUUID) {
        _takePhotoCharacteristicUUID = [CBUUID UUIDWithString:@"0A7DEC5A-9007-444D-AC0A-749FB4F81DA8"];
    }
    return _takePhotoCharacteristicUUID;
}

- (CBUUID *)recordCharacteristicUUID{
    if (!_recordCharacteristicUUID) {
        _recordCharacteristicUUID = [CBUUID UUIDWithString:@"8B6DD49A-8458-4137-87D4-DCE0CEC0663F"];
    }
    return _recordCharacteristicUUID;
}


@end
