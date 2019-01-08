//
//  FRDFaceDetectionVC.h
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FRDFaceDetectionVC : UIViewController

@property (nonatomic, assign, getter=isReset) BOOL reset;
@property (nonatomic, assign, getter=isRecognition) BOOL recognition;
@property (nonatomic, copy) NSString *userName;

@end
