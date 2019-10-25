// SHOptionView.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
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
 
 // Created by zj on 2019/10/25 11:14 AM.
    

#import "SHOptionView.h"

#define kBIGFONT 20
#define kSMALLFONT 18

@interface SHOptionView ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *optionButton;

@end

@implementation SHOptionView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    
    [self addSubview:self.contentView];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect rect = self.frame;

    rect.origin.x = 0;
    rect.origin.y = 0;

    self.contentView.frame = rect;
}

- (void)setOptionItem:(SHOptionItem *)optionItem {
    _optionItem = optionItem;
    
    [_optionButton setTitle:optionItem.title forState:UIControlStateNormal];
}

// 根据比例改变文字的大小
- (void)setScale:(CGFloat)scale {
    CGFloat max = kBIGFONT * 1.0 / kSMALLFONT - 1;
    
    self.optionButton.transform = CGAffineTransformMakeScale(max * scale + 1, max * scale + 1);
    [self.optionButton setTitleColor:[UIColor colorWithRed:scale green:0 blue:0 alpha:1] forState:UIControlStateNormal];
    self.contentView.backgroundColor = [UIColor ic_colorWithHex:kBackgroundThemeColor alpha:scale];
}

- (IBAction)clickAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(clickedActionWithOptionView:)]) {
        [self.delegate clickedActionWithOptionView:self];
    }
}

@end
