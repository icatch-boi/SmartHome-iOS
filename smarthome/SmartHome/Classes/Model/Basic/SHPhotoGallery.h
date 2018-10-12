//
//  SHCameraPhotoGallery.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SHCameraObject;
@interface SHPhotoGallery : NSObject

@property (nonatomic, weak) SHCameraObject *shCamObj;

- (void)resetPhotoGalleryDataWithStartDate:(NSString *)startDate endDate:(NSString *)endDate judge:(BOOL)isJudge completeBlock:(void (^)(id obj))completeBlock;
- (void)cleanDateInfo;

@end
