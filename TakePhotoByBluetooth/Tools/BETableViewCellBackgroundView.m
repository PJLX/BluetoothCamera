//
//  BETableViewCellBackgroundView.m
//  Blued2015
//
//  Created by 李响 on 2017/4/21.
//  Copyright © 2017年 ___CHRIS ZHAO___. All rights reserved.
//

#import "BETableViewCellBackgroundView.h"

@implementation BETableViewCellBackgroundView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.backgroundColor = [UIColor gjw_colorWithHex:0xf3f4f9];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.backgroundColor = [UIColor gjw_colorWithHex:0xffffff];
    if (self.touchEnd) {
        self.touchEnd();
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.backgroundColor = [UIColor gjw_colorWithHex:0xffffff];
}

@end
