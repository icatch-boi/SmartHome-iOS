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

@interface SHFilesCell : UITableViewCell

@property (nonatomic, strong) SHDateFileInfo *dateFileInfo;
@property (nonatomic, strong) SHS3FileInfo *fileInfo;

@end

NS_ASSUME_NONNULL_END
