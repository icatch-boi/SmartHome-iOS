// XJMessageDetailTableViewCell.m

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
 
 // Created by sa on 2018/5/26 下午1:53.
    

#import "XJMessageDetailTableViewCell.h"
static NSString * const kPIR = @"PIR Notice";
static NSString * const kRing = @"Ring Notice";
static NSString * const kPIRImgName = @"message center-btn-action detection2";
static NSString * const kRingImgName = @"message center-btn-ring2";
static NSString * const kThumbImgName = @"message center-loading"; //@"default_thumb";

@interface XJMessageDetailTableViewCell()

@end

@implementation XJMessageDetailTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    _thumbnailImgView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)setMsgInfo:(MessageInfo *)msgInfo
{
    _msgInfo = msgInfo;
    if([_msgInfo getMsgType] == MessageTypeRing) {
        _typeLabel.text = kRing;
        [_typeImgView setImage:[UIImage imageNamed:kRingImgName]];
    } else {
        _typeLabel.text = kPIR;
        [_typeImgView setImage:[UIImage imageNamed:kPIRImgName]];
    }
    _dateTimeLabel.text = _msgInfo.getMsgDatetime;
    [_thumbnailImgView setImage:[UIImage imageNamed:kThumbImgName]];
#if 0
    dispatch_async(self.fileInfoQueue, ^{
        if([self.delegate respondsToSelector:@selector(getThumbnailWithMessageInfo:)]) {
            NSData * data = [self.delegate getThumbnailWithMessageInfo:_msgInfo];
            if(data.length > 0) {
                [_thumbnailImgView setImage:[UIImage imageWithData:data]];
                if([self.delegate respondsToSelector:@selector(refreshUI)]) {
                    [self.delegate refreshUI];
                }
            }
        }
    });
#endif
}
@end
