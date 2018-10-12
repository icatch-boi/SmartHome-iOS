// XJMessageDetailTableViewCell.h

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
    

#import <UIKit/UIKit.h>
#import "MessageInfo.h"
#import "MsgFileInfo.h"
@protocol DataSourceProtocol
- (NSData *)getThumbnailWithMessageInfo:(MessageInfo *)msgInfo;
- (void)refreshUI;

@end

typedef NS_ENUM(NSInteger, MessageType) {
    MessageTypeAll = 0,
    MessageTypeRing = 201,
    MessageTypePir = 100
};
static  NSString * const detailCellID = @"MessageDetailCellID";
@interface XJMessageDetailTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *typeImgView;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (nonatomic, strong) MessageInfo * msgInfo;
@property (nonatomic, strong) id delegate;
@end
