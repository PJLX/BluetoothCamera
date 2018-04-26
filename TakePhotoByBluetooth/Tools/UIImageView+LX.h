//
//  UIImageView+LX.h
//  FlowersAndTrees
//
//  Created by 李响 on 2017/5/24.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (LX)

- (void)sd_setImageWithURLString:(nullable NSString *)urlString
          placeholderImageString:(nullable NSString *)placeholderString;
@end
