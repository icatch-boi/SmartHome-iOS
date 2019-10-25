// SHOperationView.m

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
 
 // Created by zj on 2019/10/23 2:21 PM.
    

#import "SHOperationView.h"

@interface SHOperationView ()

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation SHOperationView

+ (instancetype)operationView {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self.class) bundle:nil];
    return [nib instantiateWithOwner:nil options:nil].firstObject;
}

- (void)setItem:(SHOperationItem *)item {
    _item = item;
    
    self.icon = [UIImage imageNamed:item.iconName];
    self.title = item.title;
    self.subTitle = item.subTitle;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    
    [_button setTitle:title forState:UIControlStateNormal];
}

- (void)setSubTitle:(NSString *)subTitle {
    _subTitle = subTitle;
    
    _descriptionLabel.text = subTitle;
}

- (void)setIcon:(UIImage *)icon {
    _icon = icon;
    
    [_button setImage:icon forState:UIControlStateNormal];
    [_button setImage:icon forState:UIControlStateHighlighted];
}

- (IBAction)clickAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(clickedActionWithOperationView:)]) {
        [self.delegate clickedActionWithOperationView:self];
    }
}

@end
