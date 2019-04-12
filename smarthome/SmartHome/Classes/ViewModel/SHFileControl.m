//
//  SHCameraFileControl.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHFileControl.h"
#import "SHFileTable.h"

@interface SHFileControl ()

@property (nonatomic, strong) NSArray *filterArray;

@end

@implementation SHFileControl

- (SHTableViewSelectedCellTable *)createOneCellsTable
{
    NSMutableArray *array = [NSMutableArray array];
    SHTableViewSelectedCellTable *cellsTable = [SHTableViewSelectedCellTable selectedCellTableWithParameters:array andCount:0];
    
    return cellsTable;
}

- (BOOL)isBusy
{
    BOOL retVal = [_shCamObj.sdk isBusy];
    SHLogInfo(SHLogTagAPP, @"isDownloading: %d", retVal);
    return retVal;
}

- (void)resetBusyToggle:(BOOL)value
{
    [_shCamObj.sdk setIsBusy:value];
}

- (NSUInteger)requestDownloadedPercent:(ICatchFile *)f
{
    float progress = 0;
    NSString *locatePath = nil;
    NSString *fileName = nil;
    NSDictionary *attrs = nil;
    unsigned long long downloadedBytes;
    
    if (f != NULL) {
        fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
        locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
        attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:locatePath error:nil];
        downloadedBytes = [[attrs objectForKey:@"NSFileSize"] longLongValue];
        if (f->getFileSize() > 0) {
            progress = (float)downloadedBytes / (float)f->getFileSize();
        }
    }
    
    return MAX(0, MIN(100, progress*100));
}

- (BOOL)deleteFile:(ICatchFile *)f
{
    return [_shCamObj.sdk deleteFile:f];
}

- (BOOL)downloadFile:(ICatchFile *)f
{
    return [_shCamObj.sdk downloadFile:*f path:_shCamObj.camera.cameraUid] != nil ? YES : NO;
}

- (void)tempStoreDataForBackgroundDownload:(NSMutableArray *)downloadArray
{
}

- (NSUInteger)requestDownloadedPercent2:(NSString *)locatePath fileSize:(unsigned long long)fileSize
{
    float progress = 0;
    NSDictionary *attrs = nil;
    unsigned long long downloadedBytes = 0;
    
    if (locatePath) {
        attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:locatePath error:nil];
        downloadedBytes = [[attrs objectForKey:@"NSFileSize"] longLongValue];
        if (fileSize > 0) {
            progress = (float)downloadedBytes / (float)fileSize;
        }
        SHLogInfo(SHLogTagAPP, @"downloadedBytes: %llu", downloadedBytes);
    }
    
    return MAX(0, MIN(100, progress*100));
}

- (BOOL)setSelectFileTag:(ICatchFile *)file andIsFavorite:(BOOL)isFavorite {
    return [_shCamObj.sdk setFileTag:file andIsFavorite:isFavorite];
}

- (void)getCurFilesFilter {
    ICatchFileFilter *filter = new ICatchFileFilter();
    if ([_shCamObj.sdk getFilesFilter:filter]) {
        int type = filter->getType();
        int motion = filter->getMotion();
        int favorite = filter->getFavorite();
        
        SHLogInfo(SHLogTagAPP, @"Type: %d, Motion: %d, Favorite: %d", type, motion, favorite);
        [SHTool setLocalFilesFilter:filter];
    }
}

- (int)setFilesFilter:(NSArray *)array {
    self.filterArray = array;
    
    int type = [self getCurFileFilterFileType];
    int motion = [self getCurFileFilterMonitorType];
    int favorite = [self getCurFileFilterFavoriteType];
    
    if (type && motion && favorite) {
        ICatchFileFilter *filter = new ICatchFileFilter(type, motion, favorite);
        return [_shCamObj.sdk setFilesFilter:filter];
    } else {
        return ICH_NULL;
    }
}

- (int)getCurFileFilterMonitorType {
    NSDictionary *group = self.filterArray[SHFileFilterMonitorType];
    NSArray *items = group[@"SHFileFilterMonitorType"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int motion = 0;
    
    for (NSDictionary *item in items) {
        NSString *identifier = item[@"Identifier"];
        if ([identifier isEqualToString:@"SHFileFilterMonitorType:Audio"]) {
            if ([defaults boolForKey:identifier]) {
                motion |= ICH_FILE_MONITOR_TYPE_AUDIO;
            }
        } else if ([identifier isEqualToString:@"SHFileFilterMonitorType:Manual"]) {
            if ([defaults boolForKey:identifier]) {
                motion |= ICH_FILE_MONITOR_TYPE_MANUALLY;
            }
        } else if ([identifier isEqualToString:@"SHFileFilterMonitorType:Montion"]) {
            if ([defaults boolForKey:identifier]) {
                motion |= ICH_FILE_MONITOR_TYPE_PIR;
            }
        }else if ([identifier isEqualToString:@"SHFileFilterMonitorType:Ring"]) {
            if ([defaults boolForKey:identifier]) {
                motion |= ICH_FILE_MONITOR_TYPE_RING;
            }
        }
    }
    
    return motion;
}

- (int)getCurFileFilterFileType {
    NSDictionary *group = self.filterArray[SHFileFilterFileType];
    NSArray *items = group[@"SHFileFilterFileType"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int type = 0;
    
    for (NSDictionary *item in items) {
        NSString *identifier = item[@"Identifier"];
        if ([identifier isEqualToString:@"SHFileFilterFileType:Video"]) {
            if ([defaults boolForKey:identifier]) {
                type |= ICH_FILE_TYPE_VIDEO;
            }
        } else if ([identifier isEqualToString:@"SHFileFilterFileType:Audio"]) {
            if ([defaults boolForKey:identifier]) {
                type |= ICH_FILE_TYPE_AUDIO;
            }
        } else if ([identifier isEqualToString:@"SHFileFilterFileType:Image"]) {
            if ([defaults boolForKey:identifier]) {
                type |= ICH_FILE_TYPE_IMAGE;
            }
        }
    }
    
    return type;
}

- (int)getCurFileFilterFavoriteType {
    NSDictionary *group = self.filterArray[SHFileFilterFavoriteType];
    NSArray *items = group[@"SHFileFilterFavoriteType"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int favorite = 0;
    
    for (NSDictionary *item in items) {
        NSString *identifier = item[@"Identifier"];
        if ([identifier isEqualToString:@"SHFileFilterFavoriteType:Unfavorite"]) {
            if ([defaults boolForKey:identifier]) {
                favorite |= ICH_FILE_TAG_NULL;
            }
        } else if ([identifier isEqualToString:@"SHFileFilterFavoriteType:Favorite"]) {
            if ([defaults boolForKey:identifier]) {
                favorite |= ICH_FILE_TAG_FAVORITE;
            }
        }
    }
    
    return favorite;
}

- (NSMutableArray *)resetTableViewCellDataWithDate:(NSString *)date {
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:kDateFormat];
    NSDate *curDate = [dateformatter dateFromString:date];
    NSDate *prDate = [NSDate dateWithTimeInterval:-24 * 60 * 60 * 7 sinceDate:curDate];
    
    NSString *startDate = [dateformatter stringFromDate:prDate];
    NSString *endDate = [dateformatter stringFromDate:curDate];
    
    [self getCurFilesFilter];
    
    SHLogInfo(SHLogTagAPP, @"startDate: %@, endDate: %@", startDate, endDate);
    BOOL success;
    map<string, int> storageInfoMap = [_shCamObj.sdk getFilesStorageInfoWithStartDate:startDate andEndDate:endDate success:&success];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:8];
    
    int i = 0;
    for (map<string, int>::iterator it = storageInfoMap.begin(); it != storageInfoMap.end(); ++it, ++i) {
        SHLogInfo(SHLogTagAPP, @"key: %s - value: %d", (it->first).c_str(), it->second);
        vector<ICatchFile> fileList = [_shCamObj.sdk listFilesWhithDate:it->first andStartIndex:0 andNumber:it->second];
        SHFileTable *table = [SHFileTable fileTableWithFileCreateDate:[NSString stringWithFormat:@"%s", (it->first).c_str()] andFileStorage:[SHTool calcFileSize:fileList] andFileList:fileList];
        
        [tempArray addObject:table];
    }
    
    return tempArray;
}

@end
