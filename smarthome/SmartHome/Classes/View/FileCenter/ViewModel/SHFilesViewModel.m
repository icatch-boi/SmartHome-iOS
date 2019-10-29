// SHFilesViewModel.m

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
 
 // Created by zj on 2019/10/17 7:57 PM.
    

#import "SHFilesViewModel.h"
#import "SHENetworkManagerCommon.h"
#import "SHFCDownloaderOpManager.h"

static const CGFloat kTopSpace = 8;
static const CGFloat kIconWithScreenWidthScale = 0.45;
static const CGFloat kIconWidthWithHeightScale = 16.0 / 9;
static NSString * const kOperationItemFileName = @"EditOperationItems.json";

@interface SHFilesViewModel ()

@property (nonatomic, strong) NSMutableArray<SHS3FileInfo *> *selectedFiles;
@property (nonatomic, strong) NSArray<SHOperationItem *> *operationItems;

@end

@implementation SHFilesViewModel

- (void)listFilesWithDeviceID:(NSString *)deviceID date:(NSDate *)date completion:(void (^)(NSArray<SHS3FileInfo *> * _Nullable filesInfo))completion {
    [[SHENetworkManager sharedManager] listFilesWithDeviceID:deviceID queryDate:date startKey:nil number:0 completion:^(NSArray<SHS3FileInfo *> * _Nullable filesInfo) {
        
        if (completion) {
            completion(filesInfo);
        }
    }];
}

+ (CGFloat)filesCellRowHeight {
    CGFloat screenW = [[UIScreen mainScreen] bounds].size.width;
    NSInteger space = kTopSpace;
    
    CGFloat imgViewW = screenW  * kIconWithScreenWidthScale;
    CGFloat imgViewH = imgViewW / kIconWidthWithHeightScale;
    
    CGFloat rowH = imgViewH + space * 2;
    
    return rowH;
}

- (void)addSelectedFile:(SHS3FileInfo *)fileInfo {
    if (fileInfo.selected) {
        if (![self.selectedFilesArray containsObject:fileInfo]) {
            [self.selectedFilesArray addObject:fileInfo];
        }
    } else {
        if ([self.selectedFilesArray containsObject:fileInfo]) {
            [self.selectedFilesArray removeObject:fileInfo];
        }
    }
}

- (void)addSelectedFiles:(NSArray<SHS3FileInfo *> *)filesInfo {
    [self.selectedFilesArray addObjectsFromArray:filesInfo];
}

- (void)removeSelectedFilesInArray:(NSArray<SHS3FileInfo *> *)filesInfo {
    [self.selectedFilesArray removeObjectsInArray:filesInfo];
}

- (void)clearSelectedFiles {
    [self.selectedFilesArray removeAllObjects];
}

- (NSMutableArray<SHS3FileInfo *> *)selectedFilesArray {
    return [self mutableArrayValueForKey:NSStringFromSelector(@selector(selectedFiles))];
}

- (NSMutableArray<SHS3FileInfo *> *)selectedFiles {
    if (_selectedFiles == nil) {
        _selectedFiles = [[NSMutableArray alloc] init];
    }
    
    return _selectedFiles;
}

- (NSArray<SHOperationItem *> *)operationItems {
    if (_operationItems == nil) {
        NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *jsonPath = [docDir stringByAppendingPathComponent:kOperationItemFileName];
        
        NSData *data = [[NSData alloc] initWithContentsOfFile:jsonPath];
        
        if (data == nil) {
            NSString *path = [[NSBundle mainBundle] pathForResource:kOperationItemFileName ofType:nil];
            data = [[NSData alloc] initWithContentsOfFile:path];
        }
        
        NSArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (tempArray == nil) {
            SHLogError(SHLogTagAPP, @"Serialization is failed.");
            _operationItems = [NSArray array];
        } else {
            NSMutableArray *tempMArray = [[NSMutableArray alloc] initWithCapacity:tempArray.count];
            [tempArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHOperationItem *item = [SHOperationItem operationItemWithDict:obj];
                if (item) {
                    [tempMArray addObject:item];
                }
            }];
            
            _operationItems = tempMArray.copy;
        }
    }
    
    return _operationItems;
}

- (void)deleteSelectFileWithCompletion:(void (^)(NSArray<SHS3FileInfo *> *deleteSuccess, NSArray<SHS3FileInfo *> *deleteFailed))completion {

    [[SHENetworkManager sharedManager] deleteFiles:self.selectedFiles completion:^(NSArray<SHS3FileInfo *> * _Nonnull deleteSuccess, NSArray<SHS3FileInfo *> * _Nonnull deleteFailed) {
        if (completion) {
            completion(deleteSuccess, deleteFailed);
        }
    }];
}

- (void)downloadHandleWithDeviceID:(NSString *)deviceID {
    [self.selectedFiles enumerateObjectsUsingBlock:^(SHS3FileInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[SHFCDownloaderOpManager sharedDownloader] addDownloadFile:obj];
    }];
    
    [[SHFCDownloaderOpManager sharedDownloader] startDownloadWithDeviceID:deviceID];
}

@end
