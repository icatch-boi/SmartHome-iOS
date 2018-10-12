//
//  SHCameraFileControl.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHTableViewSelectedCellTable.h"

@interface SHFileControl : NSObject

- (SHTableViewSelectedCellTable *)createOneCellsTable;

- (BOOL)isBusy;
- (void)resetBusyToggle:(BOOL)value;
- (NSUInteger)requestDownloadedPercent:(ICatchFile *)f;
- (BOOL)deleteFile:(ICatchFile *)f;
- (BOOL)downloadFile:(ICatchFile *)f;
- (void)tempStoreDataForBackgroundDownload:(NSMutableArray *)downloadArray;
- (NSUInteger)requestDownloadedPercent2:(NSString *)locatePath fileSize:(unsigned long long)fileSize;
- (BOOL)setSelectFileTag:(ICatchFile *)file andIsFavorite:(BOOL)isFavorite;

@property (nonatomic, weak) SHCameraObject *shCamObj;

- (void)getCurFilesFilter;
- (int)setFilesFilter:(NSArray *)array;
- (NSMutableArray *)resetTableViewCellDataWithDate:(NSString *)date;

@end
