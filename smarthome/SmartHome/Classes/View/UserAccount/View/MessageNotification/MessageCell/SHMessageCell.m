//
//  SHMessageCell.m
//  SmartHome
//
//  Created by ZJ on 2018/3/16.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHMessageCell.h"
#import "SHNetworkManagerHeader.h"
#import "SHUserAccountCommon.h"

@implementation SHMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMessage:(Message *)message {
    _message = message;
    
    self.textLabel.text = [![message.fromname isEqualToString:@"(null)"] ? message.fromname : @"Unknown" stringByAppendingString:@" 邀您共享Ta的相机"];
    self.detailTextLabel.text = [SHUserAccountCommon dateTransformFromString:message.time];
}

@end
