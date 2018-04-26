//
//  LXDefine.h
//  FlowersAndTrees
//
//  Created by 李响 on 2017/5/23.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LXScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define LXScreenHeight ([UIScreen mainScreen].bounds.size.height)

#define WEAKSELF __weak typeof(self) weakSelf = self;

#define DLOLazyClass(class, name) \
\
- (class *)name\
{\
if (_##name == nil) {\
_##name = [[class alloc] init];\
}\
\
return _##name;\
}

///成功拍照/录像的数量
extern NSString *const kTakePhotosCounts;
extern NSString *const kTakeVideoCounts;

@interface LXDefine : NSObject

@end
