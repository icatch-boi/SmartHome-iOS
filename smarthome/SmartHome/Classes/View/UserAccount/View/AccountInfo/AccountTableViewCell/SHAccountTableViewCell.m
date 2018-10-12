// SHAccountTableViewCell.m

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
 
 // Created by zj on 2018/5/2 下午5:36.
    

#import "SHAccountTableViewCell.h"
#import "SHUserAccountItem.h"

@interface SHAccountTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconView;


@end

@implementation SHAccountTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        self.titleLabel.textColor = [UIColor ic_colorWithHex:kButtonThemeColor];
    } else {
        self.titleLabel.textColor = [UIColor blackColor];
    }
}

- (void)setItem:(SHUserAccountItem *)item {
    _item = item;
    
    _iconView.image = [UIImage imageNamed:item.iconName];
    _titleLabel.text = item.title;
}

- (void)setFrame:(CGRect)frame {
    
    // 设置分隔线的高度
    frame.size.height -= 1;
    
    // 务必调用系统的方法
    [super setFrame:frame];
}

@end
