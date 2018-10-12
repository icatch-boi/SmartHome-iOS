//
//  UIScreen+Addition.m
//  SmartHome
//
//  Created by ZJ on 2017/8/7.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "UIScreen+Addition.h"

@implementation UIScreen (Addition)

+ (CGRect)screenBounds {
    return [UIScreen mainScreen].bounds;
}

+ (CGSize)screenSize {
    return [self screenBounds].size;
}

+ (CGFloat)screenWidth {
    return [self screenSize].width;
}

+ (CGFloat)screenHeight {
    return [self screenSize].height;
}

+ (CGFloat)scale {
    return [UIScreen mainScreen].scale;
}

@end
