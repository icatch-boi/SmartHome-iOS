//
//  VideoPlaybackProgressViewBg.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-4-14.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "VideoPlaybackBufferingView.h"

@implementation VideoPlaybackBufferingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    if (self.color) {
        [self.color set];
    } else {
        [[UIColor lightGrayColor] set];
    }
    
    CGFloat vIns = 0;
    CGFloat hIns = 0;
    CGRect r = CGRectInset(self.bounds, hIns, vIns);

    CGFloat radius = 5.0;//r.size.height;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMaxX(r), vIns);
    CGPathAddArc(path, NULL, 0, radius+vIns, radius, -M_PI/2.0, M_PI/2.0, true);
    CGPathAddArc(path, NULL, CGRectGetMaxX(r), radius+vIns, radius, M_PI/2.0, -M_PI/2.0, true);
    CGPathCloseSubpath(path);
    CGContextAddPath(c, path);
    CGContextClip(c);
    CGPathRelease(path);
    CGContextFillRect(c, CGRectMake(r.origin.x, r.origin.y, r.size.width * self.value, 11.0));
}


@end
