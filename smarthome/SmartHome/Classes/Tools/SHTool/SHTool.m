//
//  SHTool.m
//  SmartHome
//
//  Created by ZJ on 2017/4/26.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHTool.h"
//#import "LogSet.h"
#import "type/ICatchLogLevel.h"

#define kFileFilterPlistPath [[NSBundle mainBundle] pathForResource:@"SHFileFilter" ofType:@"plist"]

@implementation SHTool

+ (NSArray *)createMediaDirectoryWithPath:(NSString *)path
{
#if DEBUG
    NSAssert(path, @"path must not be nil.");
#else
    path = @"Default";
#endif
    BOOL isDir = NO;
    BOOL isDirExist= NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"SmartHome-Medias"];
    
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:mediaDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            SHLogError(SHLogTagAPP, @"Create SmartHome-Medias Directory Failed.");
        } else
            SHLogInfo(SHLogTagAPP, @"Create SmartHome-Medias Directory path: %@",mediaDirectory);
    }
    
    mediaDirectory = [mediaDirectory stringByAppendingPathComponent:path];
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:mediaDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            SHLogError(SHLogTagAPP, @"Create SmartHome-Medias/%@ Directory Failed.", path);
        } else
            SHLogInfo(SHLogTagAPP, @"Create SmartHome-Medias/%@ Directory path: %@", path, mediaDirectory);
    }
    
    NSString *photoDirectory = [mediaDirectory stringByAppendingPathComponent:@"Photos"];
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:photoDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:photoDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            SHLogError(SHLogTagAPP, @"Create SmartHome-Medias/%@/Photos Directory Failed.", path);
        } else
            SHLogInfo(SHLogTagAPP, @"Create SmartHome-Medias/%@/Photos Directory path: %@", path, photoDirectory);
    }
    
    NSString *videoDirectory = [mediaDirectory stringByAppendingPathComponent:@"Videos"];
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:videoDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:videoDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            SHLogError(SHLogTagAPP, @"Create SmartHome-Medias/%@/Videos Directory Failed.", path);
        } else
            SHLogInfo(SHLogTagAPP, @"Create SmartHome-Medias/%@/Videos Directory path: %@", path, videoDirectory);
    }
    
    return @[mediaDirectory, photoDirectory, videoDirectory];
}

+ (void)removeMediaDirectoryWithPath:(NSString *)path {
//    NSAssert(path, @"path must not be nil.");
    if (path == nil) {
        SHLogError(SHLogTagAPP, @"Media Directory path is nil.");
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"SmartHome-Medias"];
    
    NSString *removePath = [mediaDirectory stringByAppendingPathComponent:path];
    if ([[NSFileManager defaultManager] removeItemAtPath:removePath error:nil]) {
        SHLogInfo(SHLogTagAPP, @"remove Media Directory: %@ success.", removePath);
    } else {
        SHLogError(SHLogTagAPP, @"remove Media Directory failed!");
    }
}

+ (void)cleanUpDownloadDirectoryWithPath:(NSString *)path
{
    NSArray *tmpDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    for (NSString *file in  tmpDirectoryContents) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:nil];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *logFilePath = nil;
    for (NSString *fileName in  documentsDirectoryContents) {
        if (![fileName isEqualToString:@"SHCamera.sqlite"] && ![fileName isEqualToString:@"SHCamera.sqlite-shm"] && ![fileName isEqualToString:@"SHCamera.sqlite-wal"] && ![fileName isEqualToString:@"SmartHome-Medias"] && ![fileName hasSuffix:@".db"] && ![fileName hasSuffix:@".plist"]) {
            
            if ([fileName isEqualToString:@"SmartHome-Medias"]) {
                NSString *mediaPath = [documentsDirectory stringByAppendingPathComponent:fileName];
                NSArray *mediaContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaPath error:nil];
                [mediaContents enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isEqualToString:path]) {
                        NSString *deletePath = [mediaPath stringByAppendingPathComponent:obj];
                        [[NSFileManager defaultManager] removeItemAtPath:deletePath error:nil];
                    }
                }];
            } else {
                logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
                [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
            }
        }
    }
    
    // clean local thumbnail cache.
    NSString *databaseName = [path stringByAppendingString:@".db"];
    [self removeFileWithPath:[self databasePathWithName:databaseName]];
}

+ (void)enableLogSdkAtDiretctory:(NSString *)directoryName enable:(BOOL)enable {
#if 1
    Log *log = Log::getInstance();
    if (enable) {
        log->setFileLogPath(string([directoryName UTF8String]));
        log->setSystemLogOutput(false);
        log->setPtpLogLevel(LOG_LEVEL_INFO);
        log->setRtpLogLevel(LOG_LEVEL_INFO);
        log->setFileLogOutput(true);
        log->setPtpLog(true);
        log->setRtpLog(true);
        log->setDebugMode(true);
        log->start();
    } else {
        log->setFileLogOutput(false);
        log->setPtpLog(false);
        log->setRtpLog(false);
    }
#else
    LogSet *logSet = LogSet::instance();
    if(enable) {
        logSet->setPath(LOG_TYPE_SDK, string([directoryName UTF8String]));
        logSet->setLevel(LOG_TYPE_SDK, LOG_LEVEL_INFO);
        logSet->setOutToFile(LOG_TYPE_SDK, true);
        logSet->setOutToScreen(LOG_TYPE_SDK, true);
        logSet->setEnable(LOG_TYPE_SDK, true);
        
    } else {
        logSet->setEnable(LOG_TYPE_SDK, true);
        logSet->setOutToFile(LOG_TYPE_SDK, false);
        logSet->setLevel(LOG_TYPE_SDK, LOG_LEVEL_INFO);
        logSet->setPath(LOG_TYPE_SDK, string([directoryName UTF8String]));
        logSet->setOutToScreen(LOG_TYPE_SDK, true);
    }
    logSet->logStart();
#endif
}

// retrieve the default setting values
+ (NSArray *)registerDefaultsFromSHFileFilter {
    NSArray *fileFilterArray = [NSArray arrayWithContentsOfFile:kFileFilterPlistPath];
    NSDictionary *group = nil;
    NSArray *items = nil;
    
    //1. SHFileFilterMonitorType
    group = fileFilterArray[SHFileFilterMonitorType];
    items = [group objectForKey:@"SHFileFilterMonitorType"];
    
    NSMutableDictionary *defaultsToRegister_Monitor = [[NSMutableDictionary alloc] initWithCapacity:[items count]];
    for(NSDictionary *prefSpecification in items) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister_Monitor setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister_Monitor];
    
    //2. SHFileFilterFileType
    group = fileFilterArray[SHFileFilterFileType];
    items = [group objectForKey:@"SHFileFilterFileType"];
    
    NSMutableDictionary *defaultsToRegister_File = [[NSMutableDictionary alloc] initWithCapacity:[items count]];
    for(NSDictionary *prefSpecification in items) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister_File setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister_File];
    
    //3. SHFileFilterFavoriteType
    group = fileFilterArray[SHFileFilterFavoriteType];
    items = [group objectForKey:@"SHFileFilterFavoriteType"];
    
    NSMutableDictionary *defaultsToRegister_Favorite = [[NSMutableDictionary alloc] initWithCapacity:[items count]];
    for(NSDictionary *prefSpecification in items) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister_Favorite setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister_Favorite];
    
    return fileFilterArray;
}

+ (void)setLocalFilesFilter:(ICatchFileFilter *)filter {
    int type = filter->getType();
    int motion = filter->getMotion();
    int favorite = filter->getFavorite();
    
    [self setLocalFileType:type];
    [self setLocalMonitorType:motion];
    [self setLocalFavoriteType:favorite];
}

+ (BOOL)containOf:(int)value  withMember:(int)member {
    return (value & member) == member ? YES : NO;
}

+ (void)setLocalFileType:(int)type {
    NSString *keyPrefix = @"SHFileFilterFileType:";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self containOf:type withMember:ICH_FILE_TYPE_VIDEO]) {
        NSString *key = [NSString stringWithFormat:@"%@Video", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    
    if ([self containOf:type withMember:ICH_FILE_TYPE_AUDIO]) {
        NSString *key = [NSString stringWithFormat:@"%@Audio", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    
    if ([self containOf:type withMember:ICH_FILE_TYPE_IMAGE]) {
        NSString *key = [NSString stringWithFormat:@"%@Image", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    
    if (type == ICH_FILE_TYPE_ALL) {
        NSString *key = [NSString stringWithFormat:@"%@Video", keyPrefix];
        [defaults setBool:YES forKey:key];
        key = [NSString stringWithFormat:@"%@Audio", keyPrefix];
        [defaults setBool:YES forKey:key];
        key = [NSString stringWithFormat:@"%@Image", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
}

+ (void)setLocalMonitorType:(int)motion {
    NSString *keyPrefix = @"SHFileFilterMonitorType:";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self containOf:motion withMember:ICH_FILE_MONITOR_TYPE_AUDIO]) {
        NSString *key = [NSString stringWithFormat:@"%@Audio", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    
    if ([self containOf:motion withMember:ICH_FILE_MONITOR_TYPE_MANUALLY]) {
        NSString *key = [NSString stringWithFormat:@"%@Manual", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    
    if ([self containOf:motion withMember:ICH_FILE_MONITOR_TYPE_PIR]) {
        NSString *key = [NSString stringWithFormat:@"%@Montion", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    if ([self containOf:motion withMember:ICH_FILE_MONITOR_TYPE_RING]) {
        NSString *key = [NSString stringWithFormat:@"%@Ring", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    if (motion == ICH_FILE_MONITOR_TYPE_ALL) {
        NSString *key = [NSString stringWithFormat:@"%@Audio", keyPrefix];
        [defaults setBool:YES forKey:key];
        key = [NSString stringWithFormat:@"%@Manual", keyPrefix];
        [defaults setBool:YES forKey:key];
        key = [NSString stringWithFormat:@"%@Montion", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
}

+ (void)setLocalFavoriteType:(int)favorite {
    NSString *keyPrefix = @"SHFileFilterFavoriteType:";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self containOf:favorite withMember:ICH_FILE_TAG_NULL]) {
        NSString *key = [NSString stringWithFormat:@"%@Unfavorite", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    
    if ([self containOf:favorite withMember:ICH_FILE_TAG_FAVORITE]) {
        NSString *key = [NSString stringWithFormat:@"%@Favorite", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
    
    if (favorite == ICH_FILE_TAG_ALL) {
        NSString *key = [NSString stringWithFormat:@"%@Unfavorite", keyPrefix];
        [defaults setBool:YES forKey:key];
        key = [NSString stringWithFormat:@"%@Favorite", keyPrefix];
        [defaults setBool:YES forKey:key];
    }
}

+ (unsigned long long)calcFileSize:(vector<ICatchFile>)fileList {
    unsigned long long fileSize = 0;
    
    for(vector<ICatchFile>::iterator it = fileList.begin();
        it != fileList.end();
        ++it) {
        ICatchFile f = *it;
        
        fileSize = f.getFileSize()>>10;;
    }
    
    SHLogInfo(SHLogTagAPP, @"fileListSize: %llu", fileSize);
    return fileSize;
}

+ (void)removeFileWithPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:path]) {
        BOOL success =  [fileManager removeItemAtPath:path error:nil];
        SHLogInfo(SHLogTagAPP, @"remove file is success: %d, path: %@", success, path);
    } else {
        SHLogWarn(SHLogTagAPP, @"remove file but file no exist, path: %@", path);
    }
}

+ (NSString *)databasePathWithName:(NSString *)databaseName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *documentDirectory = [paths lastObject];
    return [documentDirectory stringByAppendingPathComponent:databaseName];
}

+ (NSString *)createDownloadComplete:(NSDictionary *)tempDict {
    const char *fileName = "file";
    if ([tempDict.allKeys containsObject:@"file"]) {
        SHFile *file = tempDict[@"file"];
        
        if ([file isKindOfClass:[SHFile class]]) {
            fileName = file.f.getFileName().c_str();
        } else if ([file isKindOfClass:[NSString class]]) {
            fileName = ((NSString *)file).UTF8String;
        }
    }
    
    NSString *cameraName = @"One camera";
    if ([tempDict.allKeys containsObject:@"cameraName"]) {
        cameraName = tempDict[@"cameraName"];
    }
    
    NSString *description = @"下载完成";
    if ([tempDict.allKeys containsObject:@"Description"]) {
        description = tempDict[@"Description"];
    }
    
    NSString *msg = [NSString stringWithFormat:@"%@ 中的文件 %s %@。", cameraName, fileName, description];
    
    SHLogInfo(SHLogTagAPP, @"Download complete message: %@", msg);
    
    return msg;
}

+ (NSString *)bitRateStringFromBits:(CGFloat)bitCount
{
    CGFloat numberOfBit = bitCount;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"kb", @"Mb", @"Gb", @"Tb", @"Pb", @"Eb", @"Zb", @"Yb", nil];
    
    while (numberOfBit > 1024) {
        numberOfBit /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%.1f%@/s", numberOfBit, [tokens objectAtIndex:multiplyFactor]];
}

@end
