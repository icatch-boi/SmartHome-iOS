//
//  SHDownloader.h
//  SmartHome
//
//  Created by ZJ on 2017/6/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol SHDownloadInfoDelegate <NSObject>
- (void)onDownloadComplete:(SHFile*)file retvalue:(Boolean)ret;;
- (void)onCancelDownloadComplete:(SHFile*)file retvalue:(Boolean)ret;
- (void)onProgressUpdate:(SHFile*)file progress:(int)progress;
@end
@interface SHDownloader : NSObject
@property (nonatomic,weak) id<SHDownloadInfoDelegate> delegate;
- (instancetype)initWithCameraObject:(SHCameraObject *)camObj;

- (void)cancelDownloadFile:(SHFile *)file successBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock;
- (Boolean)cancelDownloadFile:(SHFile *)file;
- (void)downloadFile:(SHFile *)file;
@end
