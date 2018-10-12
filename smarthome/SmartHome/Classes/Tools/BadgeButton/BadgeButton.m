//
//  BadgeButton.m
//  buttonTest
//
//  Created by ZJ on 2017/8/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "BadgeButton.h"

#define SPColor(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

@interface BadgeButton ()

@property (nonatomic, strong) UILabel *badgeLab;

@end

@implementation BadgeButton
//override
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    [self addBadgeSubview];
    
    return self;
}
//override
- (instancetype)init {
    self = [super init];

    [self addBadgeSubview];

    return self;
}

- (void)addBadgeSubview {
    if (self) {
        _badgeLab = [[UILabel alloc] init];
        _badgeLab.backgroundColor = SPColor(251, 85, 85, 1);
        _badgeLab.font = [UIFont systemFontOfSize:10];
        _badgeLab.textColor = [UIColor whiteColor];
        _badgeLab.clipsToBounds = YES;
        _badgeLab.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_badgeLab];
    }
}

//override
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setSubFrame];
}

- (void)setIsRedBall:(BOOL)isRedBall {
    _isRedBall = isRedBall;
    [self setSubFrame];
}

- (void)setSubFrame {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat badgeH;
        CGFloat badgeW;
        
        [self showText];
        
        if (_isRedBall) {
            badgeH = 8;
            badgeW = 8;
        } else {
            badgeH = 15;
            badgeW = [_badgeLab sizeThatFits:CGSizeMake(MAXFLOAT, badgeH)].width + 5;
            if (badgeW > 40) {
                badgeW = 40;
            }
            if (badgeW < badgeH) {
                badgeW = badgeH;
            }
        }
        
        _badgeLab.frame = CGRectMake(0, 0, badgeW, badgeH);
        _badgeLab.layer.cornerRadius = badgeH / 2;
        
        if (self.imageView.image) {
            CGPoint center = CGPointMake(CGRectGetMaxX(self.imageView.frame), self.imageView.frame.origin.y);
            _badgeLab.center = center;
        } else {
            CGPoint center = CGPointMake(self.bounds.size.width, self.bounds.origin.y);
            _badgeLab.center = center;
        }
    });
}

- (void)setBadgeValue:(NSInteger)badgeValue {
    _badgeValue = badgeValue;
    [self setSubFrame];
}

- (void)showText {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_badgeValue <= 0) {
            _badgeLab.hidden = YES;
        } else {
            _badgeLab.hidden = NO;
        }
        
        if (_isRedBall) {
            _badgeLab.text = @"";
        } else {
            if (_badgeValue > 99) {
                _badgeLab.text = @"99+";
            } else {
                _badgeLab.text = [NSString stringWithFormat:@"%ld",(long)_badgeValue];
            }
        }
    });
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
