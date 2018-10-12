// ZJPhotoBrowserController.h

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
 
 // Created by zj on 2018/5/29 下午1:48.
    

#import <UIKit/UIKit.h>
#import "ZJPhoto.h"

@class ZJPhotoBrowserController;
@protocol ZJPhotoBrowserControllerDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(ZJPhotoBrowserController *)photoBrowser;
- (id <ZJPhotoProtocol>)photoBrowser:(ZJPhotoBrowserController *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional
- (id <ZJPhotoProtocol>)photoBrowser:(ZJPhotoBrowserController *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(ZJPhotoBrowserController *)photoBrowser deletePhotoAtIndex:(NSUInteger)index completionHandler:(nullable void(^)(BOOL success))completionHandler;

@end

@class ZJPhotoViewerController;
@interface ZJPhotoBrowserController : UIViewController

@property (nonatomic, assign) BOOL enableGrid;
@property (nonatomic, assign) BOOL startOnGrid;
@property (nonatomic, strong) UIColor *backgroundColor; // default blackColor
@property (nonatomic, strong) ZJPhotoViewerController *currentViewer;

@property (nonatomic, weak) id <ZJPhotoBrowserControllerDelegate> delegate;

- (instancetype)initWithPhotos:(NSArray *)photoArray;
- (instancetype)initWithDelegate:(id <ZJPhotoBrowserControllerDelegate>)delegate;

- (NSUInteger)numberOfPhotos;
- (id<ZJPhotoProtocol>)photoAtIndex:(NSUInteger)index;
- (id<ZJPhotoProtocol>)thumbPhotoAtIndex:(NSUInteger)index;
- (UIImage *)imageForPhoto:(id<ZJPhotoProtocol>)photo;
- (void)setCurrentPhotoIndex:(NSUInteger)index;
- (void)hideGrid:(BOOL)animated;

@end
