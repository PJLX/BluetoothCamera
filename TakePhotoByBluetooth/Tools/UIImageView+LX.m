//
//  UIImageView+LX.m
//  FlowersAndTrees
//
//  Created by 李响 on 2017/5/24.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "UIImageView+LX.h"
#import "UIImageView+WebCache.h"

@implementation UIImageView (LX)

- (void)sd_setImageWithURLString:(nullable NSString *)urlString
          placeholderImageString:(nullable NSString *)placeholderString{
    if (placeholderString == nil) {
        placeholderString = @"imgPlaceHolder";
    }
    [self sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:placeholderString]];
}

@end
