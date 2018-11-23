//
//  SHCameraPhotoGallery.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^requestPhotoGalleryDataBlock)(BOOL isSuccess, id obj);

@class SHCameraObject;
@interface SHPhotoGallery : NSObject

@property (nonatomic, weak) SHCameraObject *shCamObj;

- (void)resetPhotoGalleryDataWithStartDate:(NSString *)startDate endDate:(NSString *)endDate judge:(BOOL)isJudge completeBlock:(requestPhotoGalleryDataBlock)completeBlock;
- (void)cleanDateInfo;

@end
