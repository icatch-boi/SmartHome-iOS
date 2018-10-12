// SHCameraViewCell.h

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
 
 // Created by zj on 2018/3/21 下午2:06.
    

#import <UIKit/UIKit.h>
#import "SHCameraViewModel.h"

@class SHCameraViewCell;
@protocol SHCameraViewCellDelegate <NSObject>

- (void)enterPreviewWithCell:(SHCameraViewCell *)cell;
- (void)enterMessageCenterWithCell:(SHCameraViewCell *)cell;
- (void)enterLocalAlbumWithCell:(SHCameraViewCell *)cell;
- (void)enterShareWithCell:(SHCameraViewCell *)cell;
- (void)longPressDeleteCamera:(SHCameraViewCell *)cell;

@end

@interface SHCameraViewCell : UITableViewCell

@property (nonatomic, strong) SHCameraViewModel *viewModel;
@property (nonatomic, weak) id<SHCameraViewCellDelegate> delegate;

@end
