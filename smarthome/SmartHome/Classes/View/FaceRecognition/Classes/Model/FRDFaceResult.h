//
//  FRDFaceResult.h
//  FaceRecognition
//
//  Created by ZJ on 2019/1/3.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FRDFaceResult : NSObject

@property (nonatomic, copy) NSString *faceID;
@property (nonatomic, weak) CALayer *faceLayer;
@property (nonatomic, assign) BOOL isSuccess;

@end

NS_ASSUME_NONNULL_END
