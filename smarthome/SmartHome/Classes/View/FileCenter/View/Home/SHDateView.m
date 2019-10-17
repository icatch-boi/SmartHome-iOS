//
//  SHDateView.m
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "SHDateView.h"

#define kBIGFONT 20
#define kSMALLFONT 16

@interface SHDateView ()

@property (weak, nonatomic) IBOutlet UIButton *dateButton;
@property (weak, nonatomic) IBOutlet UIView *existView;

@end

@implementation SHDateView

+ (instancetype)dateViewWithTitle:(NSString *)title {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    SHDateView *view = [nib instantiateWithOwner:nil options:nil][0];
    [view.dateButton setTitle:title forState:UIControlStateNormal];
    
    view.dateButton.titleLabel.font = [UIFont systemFontOfSize:kBIGFONT];
    [view.dateButton.titleLabel sizeToFit];

    view.dateButton.titleLabel.font = [UIFont systemFontOfSize:kSMALLFONT];
    
//    view.dateButton.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256) / 255.0 green:arc4random_uniform(256) / 255.0 blue:arc4random_uniform(256) / 255.0 alpha:1.0];

    return view;
}

// 根据比例改变文字的大小
- (void)setScale:(CGFloat)scale {
    CGFloat max = kBIGFONT * 1.0 / kSMALLFONT - 1;
    
    self.dateButton.transform = CGAffineTransformMakeScale(max * scale + 1, max * scale + 1);
    [self.dateButton setTitleColor:[UIColor colorWithRed:scale green:0 blue:0 alpha:1] forState:UIControlStateNormal];
}

- (IBAction)dateButtonClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(clickedActionWithDateView:)]) {
        [self.delegate clickedActionWithDateView:self];
    }
}

@end
