//
//  FRDFaceShowViewController.h
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FRDFaceInfo;
@class FRDFaceInfoViewModel;
@interface FRDFaceDisplayVC : UIViewController

//@property (nonatomic, copy) NSString *userName;
@property (nonatomic, strong) FRDFaceInfo *faceInfo;
@property (nonatomic, strong) FRDFaceInfoViewModel *faceInfoViewModel;

@end
