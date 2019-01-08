//
//  FRDUploadViewController.h
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FRDResultHandleVC : UIViewController

@property (nonatomic, strong) UIImage *picture;
@property (nonatomic, assign) BOOL reset;
@property (nonatomic, assign) BOOL recognition;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, strong) NSArray<UIImage *> *images;

@end
