//
//  SHCameraPhotoGallery.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHPhotoGallery.h"
#import "SHFileTable.h"
#import "SHGUIHandleTool.h"

#define kDateSpan 8

@interface SHPhotoGallery ()

@property (nonatomic, strong) NSMutableArray *curDateStorageInfoArray;
@property (nonatomic, strong) NSMutableDictionary *curMonthStorageInfoDict;
@property (nonatomic, copy) NSString *curDate;
@property (nonatomic, copy) NSString *curMonth;
@property (nonatomic, assign) BOOL isSuccess;

@end

@implementation SHPhotoGallery

- (NSMutableArray *)curDateStorageInfoArray {
    if (!_curDateStorageInfoArray) {
        _curDateStorageInfoArray = [NSMutableArray arrayWithCapacity:kDateSpan];
    }
    
    return _curDateStorageInfoArray;
}

- (NSMutableDictionary *)curMonthStorageInfoDict {
    if (!_curMonthStorageInfoDict) {
        _curMonthStorageInfoDict = [NSMutableDictionary dictionary];
    }
    
    return _curMonthStorageInfoDict;
}

- (void)cleanDateInfo {
    self.curDate = nil;
    self.curMonth = nil;
}

- (void)resetPhotoGalleryDataWithStartDate:(NSString *)startDate endDate:(NSString *)endDate judge:(BOOL)isJudge completeBlock:(requestPhotoGalleryDataBlock)completeBlock {
    WEAK_SELF(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        STRONG_SELF(self);
		if (isJudge) {
            if (endDate) {
                if (![self isCurrentMonth:startDate]) {
                    [self createOnePhotoGalleryWithStartDate:startDate endDate:endDate];
                }
            } else {
                if (![self isCurrentDate:startDate]) {
                    [self createOnePhotoGalleryWithStartDate:startDate endDate:endDate];
                }
            }
        } else {
            [self createOnePhotoGalleryWithStartDate:startDate endDate:endDate];
        }
        
        if (completeBlock) {
            if (endDate) {
                completeBlock(self.isSuccess, self.curMonthStorageInfoDict);
            } else {
                completeBlock(self.isSuccess, self.curDateStorageInfoArray);
            }
        }
    });
}

- (NSString *)getCurrentMonth:(NSString *)newDate {
    return [newDate substringToIndex:7];
}

- (NSString *)getCurrentDate:(NSString *)newDate {
    NSArray *tempDateArray = [newDate componentsSeparatedByString:@" "];
    return tempDateArray.firstObject;
}

- (BOOL)isCurrentMonth:(NSString *)newDate {
    if (self.curMonth == nil) {
        return NO;
    }
    
    NSString *newMonth = [self getCurrentMonth:newDate];
    
    return [newMonth isEqualToString:self.curMonth];
}

- (BOOL)isCurrentDate:(NSString *)newDate {
    if (self.curDate == nil) {
        return NO;
    }
    
    NSString *curDate = [self getCurrentDate:newDate];
    
    return [curDate isEqualToString:self.curDate];
}

- (void)createOnePhotoGalleryWithStartDate:(NSString *)startDate endDate:(NSString *)endDate {
    if (endDate) {
        [self createCurMonthPhotoGalleryWithStartDate:startDate endDate:endDate];
    } else {
        [self createCurrentPhotoGalleryWithDate:startDate];
    }
}

- (void)createCurrentPhotoGalleryWithDate:(NSString *)date {
    if (date == nil) {
        SHLogError(SHLogTagAPP, @"date is nil.");
        return;
    }
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:kDateFormat];
    NSDate *curDate = [dateformatter dateFromString:date];
    NSDate *prDate = [NSDate dateWithTimeInterval:-24 * 60 * 60 * (kDateSpan /*- 1*/) sinceDate:curDate];

    NSString *startDate = [dateformatter stringFromDate:prDate];
    NSString *endDate = [dateformatter stringFromDate:curDate];
    
    [self.shCamObj.controler.fileCtrl getCurFilesFilter];
    
    SHLogInfo(SHLogTagAPP, @"startDate: %@, endDate: %@", startDate, endDate);
    BOOL success;
	SHLogInfo(SHLogTagAPP, @"storageInfoMap storageInfoMap storageInfoMap");
    map<string, int> storageInfoMap = [_shCamObj.sdk getFilesStorageInfoWithStartDate:startDate andEndDate:endDate success:&success];
    
    self.isSuccess = success;
    // clear
    [self.curDateStorageInfoArray removeAllObjects];
    
    int i = 0;
    for (map<string, int>::iterator it = storageInfoMap.begin(); it != storageInfoMap.end(); ++it, ++i) {
        SHLogInfo(SHLogTagAPP, @"key: %s - value: %d", (it->first).c_str(), it->second);
        vector<ICatchFile> fileList = [_shCamObj.sdk listFilesWhithDate:it->first andStartIndex:0 andNumber:it->second];
        SHFileTable *table = [SHFileTable fileTableWithFileCreateDate:[NSString stringWithFormat:@"%s", (it->first).c_str()] andFileStorage:[SHTool calcFileSize:fileList] andFileList:fileList];
        
        [self.curDateStorageInfoArray addObject:table];
    }
    
    if (success) {
        self.curDate = [self getCurrentDate:date];
    }
}

- (void)createCurMonthPhotoGalleryWithStartDate:(NSString *)startDate endDate:(NSString *)endDate {
    SHLogInfo(SHLogTagAPP, @"startDate: %@, endDate: %@", startDate, endDate);
    if (startDate == nil) {
        SHLogError(SHLogTagAPP, @"startDate is nil.");
        return;
    }
	
    BOOL success;
    map<string, int> storageInfoMap = [_shCamObj.sdk getFilesStorageInfoWithStartDate:startDate andEndDate:endDate success:&success];
    
    self.isSuccess = success;
    //clear
    [self.curMonthStorageInfoDict removeAllObjects];
    
    for (map<string, int>::iterator it = storageInfoMap.begin(); it != storageInfoMap.end(); ++it) {
        SHLogInfo(SHLogTagAPP, @"key: %s - value: %d", (it->first).c_str(), it->second);
        [self.curMonthStorageInfoDict setObject:@(it->second) forKey:[NSString stringWithFormat:@"%s", it->first.c_str()]];
    }
    
    SHLogInfo(SHLogTagAPP, @"storageInfoDit: %@", self.curMonthStorageInfoDict);
    if (success) {
        self.curMonth = [self getCurrentMonth:startDate];
    }
}

@end
