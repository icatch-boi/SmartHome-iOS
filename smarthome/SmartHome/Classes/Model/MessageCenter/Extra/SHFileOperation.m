//
//  SHFileOperation.m
//  Sqlite3Test
//
//  Created by sa on 20/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import "SHFileOperation.h"
#import "TimeHelper.h"
#import "MsgFileInfo.h"
#import "SHCameraManager.h"
#import "SHCameraObject.h"
#import "type/ICatchFile.h"


@interface SHFileOperation()
@property (nonatomic, strong) NSString *uuid;
@end
@implementation SHFileOperation

SHCameraObject * getCameraWithUUID(NSString* uuid)
{
    SHCameraManager *manager = [SHCameraManager sharedCameraManger];
    SHCameraObject* obj = [manager getSHCameraObjectWithCameraUid:uuid];
    if(obj == nil) {
        return nil;
    }
    
    if(![obj isConnect]) {
        //连接相机失败，则返回空，什么都不做
        int ret = [obj connectCamera];
        if(ret != 0) {
            return nil;
        }
    }
    return obj;
}



NSString* getDateFromDatetime(NSString* datetime)
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:datetime];
    [df setDateFormat:@"yyyy/MM/dd"];
    return [df stringFromDate:date];
}

-(BOOL) loginWithInfo:(NSString *)info
{
    _uuid = info;
    NSLog(@"hello , your message : %@", info);
    SHCameraObject *cameraObj = getCameraWithUUID(_uuid);
    if(cameraObj == nil) {
        return NO;
    }
    return YES;
}



-(NSArray <MsgFileInfo*>*) getFileWithStartDatetime:(NSString *)dateTime andEndDateTime:(NSString *)endDateTime
{

    //需要将datetime 转换为 date
    NSString *start = getDateFromDatetime(dateTime);
    NSString *end = getDateFromDatetime(dateTime);
    NSMutableArray *arr = [NSMutableArray new];
    SHCameraObject *cameraObj = getCameraWithUUID(_uuid);
    if (cameraObj == nil) {
        return [arr copy];
    }
    
    BOOL success = NO;
    map<string, int> storageInfoMap = [cameraObj.sdk getFilesStorageInfoWithStartDate:start andEndDate:end success:&success];
    if (!success) {
        return [arr copy];
    }
    int i = 0;

    for (map<string, int>::iterator it = storageInfoMap.begin(); it != storageInfoMap.end(); ++it, ++i) {
        SHLogInfo(SHLogTagAPP, @"key: %s - value: %d", (it->first).c_str(), it->second);
        vector<ICatchFile> fileList = [cameraObj.sdk listFilesWhithDate:it->first andStartIndex:0 andNumber:it->second];
        for (vector<ICatchFile>::iterator it = fileList.begin(); it != fileList.end(); ++it) {
            
            MsgFileInfo *info = [MsgFileInfo new];
            info.handle = it->getFileHandle();
            info.name = [NSString stringWithFormat:@"%s", it->getFileName().c_str()];
            info.duration = it->getFileDuration();
            info.thumnailSize = it->getFileThumbSize();
            
            NSString *dateTime = [NSString stringWithFormat:@"%s %s", it->getFileDate().c_str(), it->getFileTime().c_str()];
            info.datetime = [TimeHelper outterFormatToInnerFormat:dateTime];

            [arr addObject:info];
        }
    }
    return [arr copy];
}

-(NSData*) getThumbnailWithFileinfo:(MsgFileInfo *)info
{
  
    NSData* data = nil;
    //    ICatchFile(int fileHandle, int fileSize, int fileDuration, std::string fileName,
    //std::string guid, std::string fileDate, std::string fileTime, int fileMotion,
    //ICatchFileType fileType, int fileThumbSize, bool fileFavorite);
    ICatchFile file(info.handle, 0, info.duration, info.name.UTF8String, "", "date not need", "time not need", 0, ICH_FILE_TYPE_VIDEO, info.thumnailSize, NO);
    
    SHCameraObject *cameraObj = getCameraWithUUID(_uuid);
    if (cameraObj == nil) {
        return data;
    }
    data = [cameraObj.controler.propCtrl requestThumbnail:&file andPropertyID:TRANS_PROP_GET_FILE_THUMBNAIL andCamera:cameraObj];
    return data;
}

@end
