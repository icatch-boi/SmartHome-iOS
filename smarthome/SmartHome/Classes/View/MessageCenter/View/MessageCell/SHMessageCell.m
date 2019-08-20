// SHMessageCell.m

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
 
 // Created by zj on 2019/7/26 3:42 PM.
    

#import "SHMessageCell.h"
#import "SHMessageInfo.h"
#import "SHUserAccountCommon.h"

@interface SHMessageCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation SHMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self setupGUI];
}

- (void)setupGUI {
    _timeLabel.numberOfLines = 0;
    _timeLabel.font = [UIFont systemFontOfSize:14.0];
    _timeLabel.textColor = [UIColor ic_colorWithHex:kTextColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMessageInfo:(SHMessageInfo *)messageInfo {
    _messageInfo = messageInfo;
    
    _titleLabel.text = [self translateMessageType:messageInfo.message.msgType.unsignedIntegerValue];
    _timeLabel.text = [SHUserAccountCommon dateTransformFromString:messageInfo.time];
    _iconImgView.image = [[UIImage imageNamed:@"empty_photo"] ic_cornerImageWithSize:self.iconImgView.bounds.size radius:kImageCornerRadius];

    
    WEAK_SELF(self);
    [messageInfo getMessageFileWithCompletion:^(UIImage * _Nullable image) {
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.iconImgView.image = [image ic_cornerImageWithSize:self.iconImgView.bounds.size radius:kImageCornerRadius];
            });
        }
    }];
}

- (NSString *)translateMessageType:(int)type {
    NSString *str = nil;
    
    switch (type) {
        case PushMessageTypePir:
            str = NSLocalizedString(@"kMonitorTypePir", nil);
            break;
        case PushMessageTypeRing:
            str = NSLocalizedString(@"kMonitorTypeRing", nil);
            break;
            
        case PushMessageTypeLowPower:
            str = @"LowPower";
            break;
            
        case PushMessageTypeSDCardFull:
            str = @"SDCardFull";
            break;
            
        case PushMessageTypeSDCardError:
            str = @"SDCardError";
            break;
            
        case PushMessageTypeFDHit:
            str = @"FD Hit";
            break;
            
        case PushMessageTypeFDMiss:
            str = @"FD Miss";
            break;
            
        case PushMessageTypePushTest:
            str = @"PushTest";
            break;
            
        case PushMessageTypeTamperAlarm:
            str = @"Demolish";
            break;
            
        default:
            str = @"unknown";
            break;
    }
    
    return str;
}

@end
