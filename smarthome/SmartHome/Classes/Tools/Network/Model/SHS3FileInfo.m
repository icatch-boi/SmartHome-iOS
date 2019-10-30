// SHS3FileInfo.m

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
 
 // Created by zj on 2019/10/8 8:04 PM.
    

#import "SHS3FileInfo.h"

@interface SHS3FileInfo ()

@property (nonatomic, copy) NSString *datetime;
@property (nonatomic, copy) NSString *duration;
@property (nonatomic, copy) NSString *monitor;
@property (nonatomic, copy) NSString *videosize;

@end

@implementation SHS3FileInfo

- (instancetype)initWithFileInfoDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

+ (instancetype)s3FileInfoWithFileInfoDict:(NSDictionary *)dict {
    return [[self alloc] initWithFileInfoDict:dict];
}

- (NSString *)description
{
    NSArray *array = @[@"key", @"fileName", @"filePath", @"thumbnail"];
    return [NSString stringWithFormat:@"<%@: %p, %@>", self.class, self, [self dictionaryWithValuesForKeys:array].description];
}

- (id)copyWithZone:(NSZone *)zone {
    SHS3FileInfo *fileInfo = [[SHS3FileInfo allocWithZone:zone] init];
    
    fileInfo.datetime = self.datetime;
    fileInfo.duration = self.duration;
    fileInfo.monitor = self.monitor;
    fileInfo.videosize = self.videosize;
    fileInfo.key = self.key;
    fileInfo.fileName = self.fileName;
    fileInfo.filePath = self.filePath;
    fileInfo.thumbnail = self.thumbnail;
    fileInfo.deviceID = self.deviceID;
    
    fileInfo.selected = self.selected;
    fileInfo.downloadState = self.downloadState;
    
    return fileInfo;
}

@end
