//
//  SHCheckIndicator.m
//  AnimationDemo
//
//  Created by ZJ on 2017/12/15.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHCheckIndicator.h"

@interface SHCheckIndicator ()

@property (nonatomic, weak) UIView *circleView;
@property (nonatomic) NSTimer *refreshTimer;
@property (nonatomic) long times;

@end

@implementation SHCheckIndicator

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGUI];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupGUI];
    }
    
    return self;
}

- (void)setupGUI {
    [self createCircleView];
    [self createGradientLayer];
    [self setupMask];
    [self addRotateAnimation];
    [self createTitleLabel:NSLocalizedString(@"kTesting3", nil)];
}

- (NSTimer *)refreshTimer {
    if (_refreshTimer == nil) {
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTitle) userInfo:nil repeats:YES];
    }
    
    return _refreshTimer;
}

- (void)releaseTimer {
    [_refreshTimer invalidate];
    _refreshTimer = nil;
}

- (void)updateTitle {
    _times ++;
    
    int temp = _times % 3;
    NSString *title = nil;
    switch (temp) {
        case 0:
            title = NSLocalizedString(@"kTesting1", nil);
            break;
            
        case 1:
            title = NSLocalizedString(@"kTesting2", nil);
            break;
            
        default:
            title = NSLocalizedString(@"kTesting3", nil);
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _titleLabel.text = title;
    });
}

- (void)createCircleView {
    self.backgroundColor = [UIColor clearColor];
    UIView *circleView = [[UIView alloc] init];
    circleView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    circleView.backgroundColor = [UIColor cyanColor];
    [self addSubview:circleView];
    _circleView = circleView;
}

- (void)createGradientLayer {
    CAGradientLayer * gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[UIColor whiteColor].CGColor, (__bridge id)[UIColor cyanColor].CGColor];
    gradientLayer.locations = @[@0.2,@1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1.0, 0);
    gradientLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [_circleView.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)setupMask {
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRelativeArc(pathRef, nil, self.frame.size.width/2.0, self.frame.size.height/2.0, self.frame.size.width < self.frame.size.height ? self.frame.size.width/2.0-5 : self.frame.size.height/2.0-5, 0, 2*M_PI);
    layer.path = pathRef;
    layer.lineWidth = 5;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor blackColor].CGColor;
    CGPathRelease(pathRef);
    _circleView.layer.mask = layer;
}

- (void)addRotateAnimation {
    CABasicAnimation *animation = [CABasicAnimation     animationWithKeyPath:@"transform.rotation.z"]; ;
    // 设定动画选项
    animation.duration = 1.0;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount = HUGE_VALF;
    // 设定旋转角度
    animation.fromValue = [NSNumber numberWithFloat:0.0]; // 起始角度
    animation.toValue = [NSNumber numberWithFloat:2 * M_PI]; // 终止角度
    [_circleView.layer addAnimation:animation forKey:@"rotate-layer"];
    
    [self refreshTimer];
}

- (void)createTitleLabel:(NSString *)title {
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textColor = [UIColor grayColor];
    label.font = [UIFont systemFontOfSize:32];
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    [self addSubview:label];
    _titleLabel = label;
}

- (void)stopAnimation {
    [_circleView.layer removeAllAnimations];
    
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRelativeArc(pathRef, nil, self.frame.size.width/2.0, self.frame.size.height/2.0, self.frame.size.width < self.frame.size.height ? self.frame.size.width/2.0-5 : self.frame.size.height/2.0-5, 0, 2*M_PI);
    layer.path = pathRef;
    layer.lineWidth = 5;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor cyanColor].CGColor;
    CGPathRelease(pathRef);
    [_circleView.layer addSublayer:layer];
    
    [self releaseTimer];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
