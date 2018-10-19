//
//  SHDownloadManager.h
//  SmartHome
//
//  Created by ZJ on 2017/6/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMaxDownloadNum 1
@protocol SHDownloadAboutInfoDelegate <NSObject>
- (void)onDownloadComplete:(int)position retValue:(Boolean)ret;
- (void)onCancelDownloadComplete:(int)position retValue:(Boolean)ret;
- (void)onProgressUpdate:(int)position progress:(int)progress;
@end
@protocol AllDownloadCompleteDelegate <NSObject>
- (void)onAllDownloadComplete;
@end

@interface SHDownloadManager : NSObject

@property (nonatomic, readonly) int downloadSuccessedNum;
@property (nonatomic, readonly) int downloadFailedNum;
@property (nonatomic, readonly) int cancelDownloadNum;

@property (nonatomic,weak) id<SHDownloadAboutInfoDelegate> downloadInfoDelegate;
@property (nonatomic,weak) id<AllDownloadCompleteDelegate> allDownloadCompletedelegate;
@property (nonatomic, readonly) NSMutableArray *downloadArray;
+ (instancetype)shareDownloadManger;
- (instancetype)init __attribute__((unavailable("Disabled. Please use the shareDownloadManger methods instead.")));

//- (void)downloadWithCameraObject:(SHCameraObject *)camObj file:(SHFile *)file downloadInfoBlock:(void (^)(int downloadInfo))downloadInfoBlock progressBlock:(void (^)(NSInteger progress))progressBlock;
- (void)downloadWithfile:(SHFile *)file;
- (Boolean)cancelDownloadFile:(SHFile *)file;
- (void)clearDownloadingByUid:(NSString*) uid;
- (void)addDownloadFile:(SHFile *)file;
- (void)startDownloadFile;
- (Boolean)isAllDownloadComplete;
- (Boolean)isExistInDownloadListByCamera:(SHCameraObject*)camera;
@end
