//
//  SHFilesCell.h
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHDateFileInfo.h"
#import "SHS3FileInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class SHFilesCell;
@protocol SHFilesCellDelegate <NSObject>

- (void)longPressGestureHandleWithCell:(SHFilesCell *)cell;

@end

@interface SHFilesCell : UITableViewCell

@property (nonatomic, strong) SHDateFileInfo *dateFileInfo;
@property (nonatomic, strong) SHS3FileInfo *fileInfo;
@property (nonatomic, assign) BOOL editState;

@property (nonatomic, weak) id<SHFilesCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
