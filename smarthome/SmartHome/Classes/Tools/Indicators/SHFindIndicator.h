//
//  SHFindIndicator.h
//  AnimationDemo
//
//  Created by ZJ on 2017/12/15.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHFindIndicator : UIView

@property(nonatomic, assign)CGFloat radiusPercent;
@property(nonatomic, strong)UIColor *fillColor;
@property(nonatomic, strong)UIColor *strokeColor;
@property(nonatomic, strong)UIColor *closedIndicatorBackgroundStrokeColor;

// prepare the download indicator
- (void)loadIndicator;

// update the downloadIndicator
- (void)setIndicatorAnimationDuration:(CGFloat)duration;

// update the downloadIndicator
- (void)updateWithTotalBytes:(CGFloat)bytes downloadedBytes:(CGFloat)downloadedBytes;

@end
