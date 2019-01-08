//
//  ZJFaceRecognition.m
//  FaceDetectionDemo-OC
//
//  Created by ZJ on 2018/9/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "ZJFaceRecognition.h"

@implementation ZJFaceRecognition

+ (void)faceImagesByFaceRecognition:(UIImage *)image resultCallback:(FacesResultCallback)resultCallback {
    CIContext *context = [[CIContext alloc] init];
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
//    NSDictionary *parmes = @{
//                             CIDetectorAccuracy: CIDetectorAccuracyHigh,
//                             };
    NSDictionary *parmes = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];

    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:parmes];
    
    NSArray<CIFeature *> *featureArr = [detector featuresInImage:ciImage];
    NSMutableArray<CIFeature *> *faceFeatureMArr = [[NSMutableArray alloc] initWithArray:featureArr];

    for (CIFeature *faceFeature in featureArr) {
        if (faceFeature.type != CIFeatureTypeFace) {
            continue;
        }
        
        CIFaceFeature *feature = (CIFaceFeature *)faceFeature;
        
        if (!feature.hasLeftEyePosition) {
            NSLog(@"--> no left eye position");
            [faceFeatureMArr removeObject:feature];
            continue;
        }
        
        if (!feature.hasRightEyePosition) {
            NSLog(@"--> no right eye position");
            [faceFeatureMArr removeObject:feature];
            continue;
        }
        
        if (!feature.hasMouthPosition) {
            NSLog(@"--> no mouth position");
            [faceFeatureMArr removeObject:feature];
            continue;
        }
    }
        
//    if (resultCallback) {
//        resultCallback(faceFeatureMArr.count);
//    }
    NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:featureArr.count];
    for (int i = 0; i< featureArr.count; i++) {
        CIImage *faceImage = [ciImage imageByCroppingToRect:[[featureArr objectAtIndex:i] bounds]];
        [mArray addObject:[[UIImage alloc] initWithCIImage:faceImage]];
    }
    
    if (resultCallback) {
        resultCallback(mArray.copy);
    }
}

+ (void)faceImageViewByFaceRecognition:(UIImageView *)imageView resultCallback:(void (^)(NSInteger))resultCallback {
    NSArray *subViews = imageView.subviews;

    for (id subview in subViews) {
        if ([subview isKindOfClass:[UIView class]]) {
            [subview removeFromSuperview];
        }
    }
    
    CIContext *context = [[CIContext alloc] init];
    
    UIImage *image = imageView.image;
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
    NSDictionary *parmes = @{
                             CIDetectorAccuracy: CIDetectorAccuracyHigh,
                             };
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:parmes];
    
    NSArray<CIFeature *> *featureArr = [detector featuresInImage:ciImage];
    NSMutableArray<CIFeature *> *faceFeatureMArr = [[NSMutableArray alloc] initWithArray:featureArr];
    
    UIView *resultView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(imageView.frame), CGRectGetHeight(imageView.frame))];
    [imageView addSubview:resultView];
    
    for (CIFeature *faceFeature in featureArr) {
        if (faceFeature.type != CIFeatureTypeFace) {
            continue;
        }
        
        CGFloat scale = [self getScale:imageView image:image];
        
        CGRect rect = CGRectMake(CGRectGetMinX(faceFeature.bounds) / scale, CGRectGetMinY(faceFeature.bounds) / scale, CGRectGetWidth(faceFeature.bounds) / scale, CGRectGetHeight(faceFeature.bounds) / scale);
        
        [resultView addSubview:[self addRedrectangleView:rect]];
        
        CIFaceFeature *feature = (CIFaceFeature *)faceFeature;
        
        if (feature.hasLeftEyePosition) {
            UIView *leftView = [self addRedrectangleView:CGRectMake(0, 0, 5, 5)];
            CGPoint position = CGPointMake(feature.leftEyePosition.x / scale, feature.leftEyePosition.y / scale);
            
            leftView.center = position;
            
            [resultView addSubview:leftView];
        } else {
            [faceFeatureMArr removeObject:feature];
            continue;
        }
        
        if (feature.hasRightEyePosition) {
            UIView *rightView = [self addRedrectangleView:CGRectMake(0, 0, 5, 5)];
            CGPoint position = CGPointMake(feature.rightEyePosition.x / scale, feature.rightEyePosition.y / scale);
            
            rightView.center = position;
            
            [resultView addSubview:rightView];
        } else {
            [faceFeatureMArr removeObject:feature];
            continue;
        }
        
        if (feature.hasMouthPosition) {
            UIView *mouthView = [self addRedrectangleView:CGRectMake(0, 0, 20, 20)];
            CGPoint position = CGPointMake(feature.mouthPosition.x / scale, feature.mouthPosition.y / scale);
            
            mouthView.center = position;
            
            [resultView addSubview:mouthView];
        } else {
            [faceFeatureMArr removeObject:feature];
            continue;
        }
    }
    
    resultView.transform = CGAffineTransformMakeScale(1, -1);
    
    if (resultCallback) {
        resultCallback(faceFeatureMArr.count);
    }
}

+ (UIView *)addRedrectangleView:(CGRect)rect {
    UIView *redView = [[UIView alloc] init];
    
    redView.layer.backgroundColor = [UIColor redColor].CGColor;
    redView.layer.borderWidth = 1;
    
    return redView;
}

+ (CGFloat)getScale:(UIImageView *)imageView image:(UIImage *)image {
    CGSize viewSize = imageView.frame.size;
    CGSize imageSize = image.size;
    
    CGFloat widthScale = imageSize.width / viewSize.width;
    CGFloat heightScale = imageSize.height / viewSize.height;
    
    return MAX(widthScale, heightScale);
}

@end
