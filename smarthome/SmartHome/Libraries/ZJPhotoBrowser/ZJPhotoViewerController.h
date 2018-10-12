//
//  ZJPhotoViewerController.h
//  ZJPhotoBrowserTest
//
//  Created by ZJ on 2018/5/29.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZJPhotoProtocol.h"

@class ZJPhoto;
@class ZJPhotoBrowserController;
@interface ZJPhotoViewerController : UIViewController

@property (nonatomic, assign) NSUInteger photoIndex;
@property (nonatomic, readonly, nonnull) UIScrollView *scrollView;
@property (nonatomic, readonly, nonnull) UIImageView *imageView;

@property (nonatomic, strong) id <ZJPhotoProtocol> photo;

- (instancetype)initWithPhotoBrowser:(ZJPhotoBrowserController *)browser photo:(ZJPhoto *)photo index:(NSUInteger)index;

@end
