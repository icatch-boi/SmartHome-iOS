//
//  ZJFaceRecognition.h
//  FaceDetectionDemo-OC
//
//  Created by ZJ on 2018/9/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^FacesResultCallback)(NSArray<UIImage *> *faceImages);
@interface ZJFaceRecognition : NSObject

+ (void)faceImagesByFaceRecognition:(UIImage *)image resultCallback:(FacesResultCallback)resultCallback;
+ (void)faceImageViewByFaceRecognition:(UIImageView *)imageView resultCallback:(void (^)(NSInteger))resultCallback;

@end
