

#import "GJColor.h"

@implementation UIColor (GJCreateColor)

+ (UIColor *)gjw_colorWithR:(float)r G:(float)g B:(float)b {
    return [self gjw_colorWithR:r G:g B:b A:1];
}

+ (UIColor *)gjw_colorWithR:(float)r G:(float)g B:(float)b A:(float)a {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a];
}

+ (UIColor *)gjw_colorWithHex:(int)hex {
    return [UIColor gjw_colorWithHex:hex alpha:1];
}

+ (UIColor *)gjw_colorWithHex:(int)hex alpha:(CGFloat)a {
    return [UIColor colorWithRed:((hex & 0xFF0000) >> 16) / 255.0 green:((hex & 0xFF00) >> 8) / 255.0 blue:(hex & 0xFF) / 255.0 alpha:a];
}

@end
