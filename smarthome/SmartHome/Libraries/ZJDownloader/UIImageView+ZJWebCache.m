// UIImageView+ZJWebCache.m

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
 
 // Created by zj on 2019/8/29 5:15 PM.
    

#import "UIImageView+ZJWebCache.h"
#import <objc/runtime.h>
#import "ZJDownloaderOperationManager.h"
#import "SVProgressHUD.h"

static const void *kAssociated = "currentURLString";

@interface UIImageView ()

@property (nonatomic, copy) NSString *currentURLString;

@end

@implementation UIImageView (ZJWebCache)

- (NSString *)currentURLString {
    return objc_getAssociatedObject(self, kAssociated);
}

- (void)setCurrentURLString:(NSString *)currentURLString {
    objc_setAssociatedObject(self, kAssociated, currentURLString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setImageURLString:(NSString *)urlString {
    [self setImageURLString:urlString cacheKey:urlString];
}

- (void)setImageURLString:(NSString *)urlString cacheKey:(NSString *)cacheKey {
    // 如果和上一次不一样，取消上一次操作(避免乱序)
    if (![urlString isEqualToString:self.currentURLString]) {
        [[ZJDownloaderOperationManager sharedDownloader] cancelOperation:self.currentURLString];
    }
    
    self.currentURLString = urlString;
    
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    [[ZJDownloaderOperationManager sharedDownloader] downloadWithURLString:urlString cacheKey:cacheKey finishedBlock:^(NSString * _Nullable url, UIImage * _Nullable image) {
        [SVProgressHUD dismiss];
        
        if (image != nil && [url isEqualToString:self.currentURLString]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
            });
        }
    }];
}

@end
