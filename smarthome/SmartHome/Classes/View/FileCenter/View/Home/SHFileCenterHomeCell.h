//
//  SHFileCenterHomeCell.h
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHDateFileInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class SHS3FileInfo;
@class SHFileCenterHomeCell;
@protocol SHFileCenterHomeCellDelegate <NSObject>

- (void)fileCenterHomeCell:(SHFileCenterHomeCell *)cell didSelectWithFileInfo:(SHS3FileInfo *)fileInfo;
- (void)enterEditeStateWithCell:(SHFileCenterHomeCell *)cell;

@end

@interface SHFileCenterHomeCell : UICollectionViewCell

@property (nonatomic, strong) SHDateFileInfo *dateFileInfo;

@property (nonatomic, weak) id<SHFileCenterHomeCellDelegate> delegate;

- (void)cancelEditAction;

@end

NS_ASSUME_NONNULL_END
