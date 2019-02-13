// XJLocalAssetHelper.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by zj on 2018/6/8 下午4:36.
    

#import "XJLocalAssetHelper.h"
#import <Photos/Photos.h>

static NSString * const kPlistName = @"XJLocalAsset";

@interface XJLocalAssetHelper ()

@property (nonatomic, copy) NSString *plistName;

@end

@implementation XJLocalAssetHelper

static XJLocalAssetHelper *instance = nil;

#pragma mark - Init
+ (instancetype)sharedLocalAssetHelper {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    
    return instance;
}

- (instancetype)init
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super init];
        if (instance) {
            instance.plistName = kPlistName;
        }
    });

    return instance;
}

#pragma mark - addNewAsset
- (BOOL)addNewAssetToLocalAlbum:(ICatchFile)file forKey:(NSString *)key {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [self createNewAssetCollection];
//    });
    
    BOOL retVal = NO;
    NSURL *fileURL = nil;
    
    NSString *fileName = [NSString stringWithUTF8String:file.getFileName().c_str()];
    NSString *locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    if (locatePath) {
        fileURL = [NSURL fileURLWithPath:locatePath];
    } else {
        return retVal;
    }
    
    switch (file.getFileType()) {
        case smarthome::ICH_FILE_TYPE_IMAGE:
            if (locatePath) {
                retVal = [self addNewAssetWithURL:fileURL toAlbum:kLocalAlbumName andFileType:ICH_FILE_TYPE_IMAGE forKey:key];
            }
            break;
            
        case smarthome::ICH_FILE_TYPE_VIDEO:
            if (locatePath && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(locatePath)) {
                retVal = [self addNewAssetWithURL:fileURL toAlbum:kLocalAlbumName andFileType:ICH_FILE_TYPE_VIDEO forKey:key];
            } else {
                SHLogError(SHLogTagAPP, @"The specified video can not be saved to user’s Camera Roll album");
            }
            break;
            
        default:
            SHLogError(SHLogTagAPP, @"Unsupported file type to download right now!!");
            break;
    }
    
    return retVal;
}

- (void)createNewAssetCollection
{
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    for (int i=0; i<topLevelUserCollections.count; ++i) {
        PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
        if ([collection.localizedTitle isEqualToString:kLocalAlbumName]) {
            return;
        }
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:kLocalAlbumName];
    } completionHandler:^(BOOL success, NSError *error) {
        SHLogInfo(SHLogTagAPP, @"Finished adding asset collection. %@", (success ? @"Success" : error));
    }];
}

- (BOOL)addNewAssetWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName andFileType:(ICatchFileType)fileType forKey:(NSString *)key
{
    __block BOOL isSuccess = NO;
    
    // Check library permissions
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                isSuccess = [self addNewAssetDetailHandleWithURL:fileURL toAlbum:albumName andFileType:fileType forKey:key];
            }
        }];
    } else if (status == PHAuthorizationStatusAuthorized) {
        isSuccess = [self addNewAssetDetailHandleWithURL:fileURL toAlbum:albumName andFileType:fileType forKey:key];
    }
    
    return isSuccess;
}

- (BOOL)addNewAssetDetailHandleWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName andFileType:(ICatchFileType)fileType forKey:(NSString *)key
{
    __block NSString *localIdentifier;
    
    NSError *error;
    BOOL retVal = [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = nil;
        if (fileType == ICH_FILE_TYPE_IMAGE) {
            createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        } else if (fileType == ICH_FILE_TYPE_VIDEO) {
            createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        } else {
            SHLogError(SHLogTagAPP, @"Unknown file type to save.");
            return;
        }
        
        PHAssetCollection *myAssetCollection = nil;
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (int i=0; i<topLevelUserCollections.count; ++i) {
            PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
            if ([collection.localizedTitle isEqualToString:albumName]) {
                PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                myAssetCollection = assetCollection;
                break;
            }
        }
        if (myAssetCollection && createAssetRequest) {
            // Request editing the album.
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:myAssetCollection];
            // Get a placeholder for the new asset and add it to the album editing request.
            PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
            
            localIdentifier = assetPlaceholder.localIdentifier;
        }
        
    } error:&error];
    
    if (!retVal) {
        SHLogError(SHLogTagAPP, @"Failed to save. %@", error.localizedDescription);
    } else {
        [self addLocalIdentifier:localIdentifier forKey:key];
    }
    return retVal;
}

- (void)addLocalIdentifier:(NSString *)localIdentifier forKey:(NSString *)key {
    if (key == nil) {
        SHLogWarn(SHLogTagAPP, @"LocalIdentifier key is nil.");
        return;
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self readFromPlist]];
    
    if (array && array.count) {
        [array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[obj allKeys].firstObject isEqualToString:key]) {
                NSMutableArray *detailArray = [NSMutableArray arrayWithArray:[obj objectForKey:key]];
                
                if (![detailArray containsObject:localIdentifier]) {
                    [detailArray addObject:localIdentifier];
                    [obj setValue:detailArray forKey:key];
                }

                *stop = YES;
            } else {
                if (idx == (array.count - 1)) {
                    [array addObject:@{key: @[localIdentifier]}];
                    *stop = YES;
                }
            }
        }];
    } else {
        [array addObject:@{key: @[localIdentifier]}];
    }
    
    [self writeDataToPlist:array];
}

#pragma mark - DeleteAsset
- (void)deleteLocalIdentifier:(NSString *)localIdentifier forKey:(NSString *)key {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self readFromPlist]];
    
    [array enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj allKeys].firstObject isEqualToString:key]) {
            NSMutableArray *detailArray = [NSMutableArray arrayWithArray:[obj objectForKey:key]];
            [detailArray removeObject:localIdentifier];
            [obj setValue:detailArray forKey:key];
            *stop = YES;
        }
    }];
    
    [self writeDataToPlist:array];
}

- (void)deleteLocalAsset:(NSString *)localIdentifier forKey:(NSString *)key completionHandler:(nullable void(^)(BOOL success))completionHandler {
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        if ([assetCollection.localizedTitle isEqualToString:kLocalAlbumName])  {
            PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:[PHFetchOptions new]];
            [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PHAsset *asset = obj;
                if ([localIdentifier isEqualToString:asset.localIdentifier]) {
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        [PHAssetChangeRequest deleteAssets:@[obj]];
                    } completionHandler:^(BOOL success, NSError *error) {
                        if (success) {
                            SHLogInfo(SHLogTagAPP, @"删除成功!");
                            [self deleteLocalIdentifier:localIdentifier forKey:key];
                        } else {
                            SHLogError(SHLogTagAPP, @"删除失败:%@", error);
                        }
                        
                        if (completionHandler) {
                            completionHandler(success);
                        }
                    }];
                }
            }];
        }
    }];
}

- (void)deleteLocalAllAssetsWithKey:(NSString *)key completionHandler:(nullable LocalAssetCompletionCallback)completionHandler {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self readFromPlist]];
    NSDictionary *desDict = nil;
    
    for (NSDictionary *dict in array) {
        if ([dict.allKeys.firstObject isEqualToString:key]) {
            desDict = dict;
            break;
        }
    }
    
    NSArray *desArray = [desDict objectForKey:key];
    if (desDict == nil || desArray == nil) {
        SHLogWarn(SHLogTagAPP, @"No have local asset, key: %@", key);
        
        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    
    NSArray *deleteAssets = [self retrieveAssetsWithLocalIdentifier:desArray];
    
    if (deleteAssets.count <= 0) {
        SHLogWarn(SHLogTagAPP, @"System album no have asset, key: %@", key);
        
        [array removeObject:desDict];
        [self writeDataToPlist:array];
        
        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    
    [self deleteAssets:deleteAssets completionHandler:^(BOOL success) {
        if (success) {
            [array removeObject:desDict];
            [self writeDataToPlist:array];
        }
        
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

- (void)deleteAssets:(id<NSFastEnumeration>)deleteAssets completionHandler:(nullable LocalAssetCompletionCallback)completionHandler {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:deleteAssets];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            SHLogInfo(SHLogTagAPP, @"删除成功!");
        } else {
            SHLogError(SHLogTagAPP, @"删除失败:%@", error);
        }
        
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

- (NSArray *)retrieveAssetsWithLocalIdentifier:(NSArray *)desArray {
    NSMutableArray *deleteAssets = [NSMutableArray array];
    
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        if ([assetCollection.localizedTitle isEqualToString:kLocalAlbumName])  {
            PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:[PHFetchOptions new]];
            [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PHAsset *asset = obj;
                if ([desArray containsObject:asset.localIdentifier]) {
                    [deleteAssets addObject:asset];
                }
            }];
        }
    }];
    
    return deleteAssets.copy;
}

#pragma mark - setter
- (void)setPlistName:(NSString *)plistName {
    if (!_plistName) {
        _plistName = plistName;
        
        //创建plist文件，记录path和localIdentifier的对应关系
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *path = [paths objectAtIndex:0];
        NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", plistName]];
        SHLogInfo(SHLogTagAPP, @"plist路径:%@", filePath);
        NSFileManager* fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:filePath]) {
            BOOL success = [fm createFileAtPath:filePath contents:nil attributes:nil];
            if (!success) {
                SHLogError(SHLogTagAPP, @"创建plist文件失败!");
            } else {
                SHLogInfo(SHLogTagAPP, @"创建plist文件成功!");
            }
        } else {
            SHLogWarn(SHLogTagAPP, @"沙盒中已有该plist文件，无需创建!");
        }
    }
    
    [self createNewAssetCollection];
}

#pragma mark - 写入plist文件
- (void)writeDataToPlist:(NSArray *)array {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", _plistName]];
    [array writeToFile:filePath atomically:YES];
}

#pragma mark - 读取plist文件
- (NSArray *)readFromPlist {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", _plistName]];
    return [NSArray arrayWithContentsOfFile:filePath];
}

@end
