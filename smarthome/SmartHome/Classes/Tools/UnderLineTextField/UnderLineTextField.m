//
//  UnderLineTextField.m
//  UnderLinerTextField
//
//  Created by ZJ on 2018/5/23.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "UnderLineTextField.h"

@interface UnderLineTextField ()

@property (nonatomic, weak) UIView *lineView;

@end

@implementation UnderLineTextField

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupGUI];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGUI];
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupGUI];
    }
    return self;
}

- (void)setupGUI {
    self.borderStyle = UITextBorderStyleNone;
    self.font = [UIFont systemFontOfSize:16.0];
//    self.placeholder = @"placeholder";
    
    UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height + 2, self.frame.size.width, 1.0)];
    line.backgroundColor = [UIColor blueColor];
    [self addSubview:line];
    
    _lineView = line;
}

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
    _lineView.backgroundColor = lineColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    _lineView.bounds = CGRectMake(0, self.frame.size.height + 2, _lineView.bounds.size.width, lineWidth);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
