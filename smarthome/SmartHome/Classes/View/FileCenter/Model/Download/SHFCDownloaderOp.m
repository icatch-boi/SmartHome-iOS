// SHFCDownloaderOp.m

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
 
 // Created by zj on 2019/10/25 6:28 PM.
    

#import "SHFCDownloaderOp.h"
#import "SHENetworkManagerCommon.h"

@interface SHFCDownloaderOp ()

@property (nonatomic, strong) SHS3FileInfo *fileInfo;
@property (nonatomic, copy) DownloadFinishedBlock finishedBlock;

@end

@implementation SHFCDownloaderOp

+ (instancetype)fileCenterDownloaderOpWithFileInfo:(SHS3FileInfo *)fileInfo finishedBlock:(DownloadFinishedBlock)finishedBlock {
    SHFCDownloaderOp *op = [[SHFCDownloaderOp alloc] init];
    
    op.fileInfo = fileInfo;
    op.finishedBlock = finishedBlock;
    
    return op;
}

- (void)main {
    @autoreleasepool {
        if (_fileInfo == nil || _fileInfo.deviceID.length == 0 || _fileInfo.filePath.length == 0) {
            SHLogError(SHLogTagAPP, @"Download failed, fileInfo or deviceID or filePath is nil.\n\t urlString: %@, url: %@, request: %@.", _fileInfo, _fileInfo.deviceID, _fileInfo.filePath);
            if (self.finishedBlock) {
                self.finishedBlock();
            }
            
            return;
        }
        
        WEAK_SELF(self);
        [[SHENetworkManager sharedManager] getFileWithDeviceID:self.fileInfo.deviceID filePath:self.fileInfo.filePath completion:^(BOOL isSuccess, id  _Nullable result) {
            if (self.isCancelled) {
                if (weakself.finishedBlock) {
                    weakself.finishedBlock();
                }
                
                return;
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (weakself.finishedBlock) {
                    weakself.finishedBlock();
                }
            }];
        }];
    }
}

@end
