// SHDownloadHomeCell.h

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
 
 // Created by zj on 2019/10/25 3:10 PM.
    

#import <UIKit/UIKit.h>
#import "SHOptionItem.h"

NS_ASSUME_NONNULL_BEGIN

@class SHDownloadHomeCell;
@protocol SHDownloadHomeCellDelegate <NSObject>

- (void)enterLocalAlbumWithCell:(SHDownloadHomeCell *)cell;

@end

@interface SHDownloadHomeCell : UICollectionViewCell

@property (nonatomic, strong) SHOptionItem *optionItem;
@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, weak) id<SHDownloadHomeCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
