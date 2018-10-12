// UIImageView+ZJAddition.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2018/7/5 下午2:24.
    

#import "UIImageView+ZJAddition.h"
#import "UIImage+ZJTint.h"

static UIColor * const kDefaultGradientColor = [UIColor redColor];
static NSTimeInterval const kDefaultDuration = 0.5;

@implementation UIImageView (ZJAddition)

+ (instancetype)imageViewWithImage:(UIImage *)image {
    return [self imageViewWithImage:image gradient:NO gradientColors:nil duration:0];
}

+ (instancetype)imageViewWithImage:(UIImage *)image gradient:(BOOL)gradient {
    return [self imageViewWithImage:image gradient:gradient gradientColors:nil duration:0];
}

+ (instancetype)imageViewWithImage:(UIImage *)image gradient:(BOOL)gradient gradientColors:(NSArray <UIColor *>*)gradientColors duration:(NSTimeInterval)duration {
    UIImage *aniImage = nil;
    
    if (gradient) {
        duration = (duration <= 0) ? kDefaultDuration : duration;
        
        NSMutableArray *gradientImgs = [NSMutableArray array];
        [gradientImgs addObject:image];
        
        if (gradientColors != nil) {
            [gradientColors enumerateObjectsUsingBlock:^(UIColor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                UIImage *gradientImg = [image imageWithTintColor:obj];
                [gradientImgs addObject:gradientImg];
            }];
        } else {
            [gradientImgs addObject:[image imageWithTintColor:kDefaultGradientColor]];
        }
        
        aniImage = [UIImage animatedImageWithImages:gradientImgs duration:duration];
    } else {
        aniImage = image;
    }
    
    return [[UIImageView alloc] initWithImage:aniImage];
}

@end
