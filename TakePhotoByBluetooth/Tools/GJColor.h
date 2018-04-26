/*!
 @header     GJColor.m
 @abstract   UIColor's category
 @discussion 提供一些便利方法创建color对象
 @author     guoxiaoliang
 */

#import <UIKit/UIKit.h>

@interface UIColor (GJCreateColor)

+ (UIColor *)gjw_colorWithR:(float)r G:(float)g B:(float)b;
+ (UIColor *)gjw_colorWithR:(float)r G:(float)g B:(float)b A:(float)a;

/**
 *  十六进制形式传入
 *  @param hex eg：0xff3355
 *  @return color对象
 */
+ (UIColor *)gjw_colorWithHex:(int)hex;
+ (UIColor *)gjw_colorWithHex:(int)hex alpha:(CGFloat)a;

@end
