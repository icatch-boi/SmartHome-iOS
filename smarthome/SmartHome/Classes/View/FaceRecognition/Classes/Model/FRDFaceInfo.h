//
//  FRDFaceInfo.h
//  FaceRecognition
//
//  Created by ZJ on 2018/9/13.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^FaceInfoGetFaceImageCompletionBlock)(UIImage * _Nullable faceImage);

@interface FRDFaceInfo : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly) NSString *faceid;
@property (nonatomic, strong) id faceDataSet;
//@property (nonatomic, strong) UIImage *faceImage;

- (instancetype)initWithDict:(NSDictionary *)dict;
+ (instancetype)faceInfoWithDict:(NSDictionary *)dict;

- (void)getFaceImageWithCompletion:(FaceInfoGetFaceImageCompletionBlock)completion;

+ (void)getFaceImageWithFaceid:(NSString *)faceid completion:(FaceInfoGetFaceImageCompletionBlock)completion;

@end
NS_ASSUME_NONNULL_END
