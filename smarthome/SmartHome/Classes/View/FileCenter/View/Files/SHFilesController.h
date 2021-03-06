//
//  SHFilesController.h
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHDateFileInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class SHS3FileInfo;
typedef void(^SHFilesControllerDidSelectBlock)(SHS3FileInfo *fileInfo);
typedef void(^SHFilesControllerEditStateBlock)();
typedef void(^SHFilesControllerEnterDownloadBlock)();

@interface SHFilesController : UIViewController

@property (nonatomic, strong) SHDateFileInfo *dateFileInfo;
@property (nonatomic, copy) SHFilesControllerDidSelectBlock didSelectBlock;
@property (nonatomic, copy) SHFilesControllerEditStateBlock editStateBlock;
@property (nonatomic, copy) SHFilesControllerEnterDownloadBlock enterDownloadBlock;

- (void)cancelEditAction;

@end

NS_ASSUME_NONNULL_END
