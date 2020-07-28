// SHAccountSettingCommonCell.m

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
 
 // Created by zj on 2019/4/15 7:48 PM.
    

#import "SHAccountSettingCommonCell.h"
#import "SHAccountSettingItem.h"

@interface SHAccountSettingCommonCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic, assign) BOOL enableFaceRecognition;

@end

@implementation SHAccountSettingCommonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    _enableFaceRecognition = [SHCameraManager sharedCameraManger].smarthomeCams.count > 0 && [SHTool checkUserWhetherHaveOwnDevice];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setItem:(SHAccountSettingItem *)item {
    [super setItem:item];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    _titleLabel.text = NSLocalizedString(item.title, nil);
    
    if ([item.title isEqualToString:@"kBiometricsRecognition"]) {
        [self enableFaceRecognitionHandlerWithCell:self];
    }
}

- (void)enableFaceRecognitionHandlerWithCell:(UITableViewCell *)cell {
    uint32_t textC;
    
    if (self.enableFaceRecognition) {
        textC = kTextColor;
        
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        textC = 0x8E8E8E;
        
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    UILabel *titleLab = cell.contentView.subviews.firstObject;
    titleLab.textColor = [UIColor ic_colorWithHex:textC];
}

@end
