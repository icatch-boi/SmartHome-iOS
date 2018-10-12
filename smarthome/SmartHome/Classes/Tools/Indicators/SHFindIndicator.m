//
//  SHFindIndicator.m
//  AnimationDemo
//
//  Created by ZJ on 2017/12/15.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHFindIndicator.h"

@interface SHFindIndicator ()

@property(nonatomic, strong)CAShapeLayer *coverLayer;
@property(nonatomic, strong)CAShapeLayer *animatingLayer;
@property(nonatomic, assign)CGFloat coverWidth;
@property(nonatomic, strong)NSMutableArray *paths;
@property(nonatomic, assign)CGFloat animationDuration;
@property(nonatomic, assign)CGFloat lastSourceAngle;

@end

@implementation SHFindIndicator

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initAttributes];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initAttributes];
    }
    
    return self;
}

- (void)initAttributes
{
    // first set the radius percent attribute
    self.radiusPercent = 0.5;
    _coverLayer = [CAShapeLayer layer];
    _animatingLayer = _coverLayer;
    
    // set the fill color
    _fillColor = [UIColor clearColor];
    _strokeColor = [UIColor whiteColor];
    _closedIndicatorBackgroundStrokeColor = [UIColor lightGrayColor];
    _coverWidth = 10.0;
    
    _animatingLayer.frame = self.bounds;
    [self.layer addSublayer:_animatingLayer];
    
    // path array
    _paths = [NSMutableArray array];
    
    // animation duration
    _animationDuration = 0.5;
}

- (void)loadIndicator
{
    // set the initial Path
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    UIBezierPath *initialPath = [UIBezierPath bezierPath]; //empty path

    [initialPath addArcWithCenter:center radius:(MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))) startAngle:degreeToRadian(-90) endAngle:degreeToRadian(-90) clockwise:YES]; //add the arc
    
    _animatingLayer.path = initialPath.CGPath;
    _animatingLayer.strokeColor = _strokeColor.CGColor;
    _animatingLayer.fillColor = _fillColor.CGColor;
    _animatingLayer.lineWidth = _coverWidth;
    self.lastSourceAngle = degreeToRadian(-90);
}

#pragma mark - update indicator
- (void)updateWithTotalBytes:(CGFloat)bytes downloadedBytes:(CGFloat)downloadedBytes
{
    [_paths removeAllObjects];
    
    CGFloat destinationAngle = [self destinationAngleForRatio:(downloadedBytes/bytes)];
    CGFloat radius = (MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) * _radiusPercent) - self.coverWidth;
    [_paths addObjectsFromArray:[self keyframePathsWithDuration:self.animationDuration lastUpdatedAngle:self.lastSourceAngle newAngle:destinationAngle  radius:radius]];
    
    _animatingLayer.path = (__bridge CGPathRef)((id)_paths[(_paths.count -1)]);
    self.lastSourceAngle = destinationAngle;
    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    [pathAnimation setValues:_paths];
    [pathAnimation setDuration:self.animationDuration];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [pathAnimation setRemovedOnCompletion:YES];
    [_animatingLayer addAnimation:pathAnimation forKey:@"path"];
    
    //[self.displayLabel updateValue:downloadedBytes/bytes];
}

- (CGFloat)destinationAngleForRatio:(CGFloat)ratio
{
    return (degreeToRadian((360*ratio) - 90));
}

float degreeToRadian(float degree)
{
    return ((degree * M_PI)/180.0f);
}

#pragma mark Helper Methods
- (NSArray *)keyframePathsWithDuration:(CGFloat)duration lastUpdatedAngle:(CGFloat)lastUpdatedAngle newAngle:(CGFloat)newAngle radius:(CGFloat)radius
{
    NSUInteger frameCount = ceil(duration * 60);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:frameCount + 1];
    for (int frame = 0; frame <= frameCount; frame++)
    {
        CGFloat startAngle = degreeToRadian(-90);
        CGFloat endAngle = lastUpdatedAngle + (((newAngle - lastUpdatedAngle) * frame) / frameCount);
        
        [array addObject:(id)([self pathWithStartAngle:startAngle endAngle:endAngle radius:radius].CGPath)];
    }
    
    return [NSArray arrayWithArray:array];
}

- (UIBezierPath *)pathWithStartAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle radius:(CGFloat)radius
{
    BOOL clockwise = startAngle < endAngle;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    [path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:clockwise];
    
    return path;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat radius = (MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))/2) - self.coverWidth;
    
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    UIBezierPath *coverPath = [UIBezierPath bezierPath]; //empty path
    [coverPath setLineWidth:_coverWidth];
    [coverPath addArcWithCenter:center radius:radius startAngle:0 endAngle:2*M_PI clockwise:YES]; //add the arc
    [_closedIndicatorBackgroundStrokeColor set];
    [coverPath setLineWidth:self.coverWidth];
    [coverPath stroke];
}

#pragma mark Setter Methods
- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = [UIColor clearColor];
}

- (void)setRadiusPercent:(CGFloat)radiusPercent
{
    _radiusPercent = 0.5;
}

- (void)setIndicatorAnimationDuration:(CGFloat)duration
{
    self.animationDuration = duration;
}

@end
