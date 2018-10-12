//
//  SHQRCodeShareVC.h
//  SmartHome
//
//  Created by ZJ on 2018/3/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHQRCodeShareVC : UIViewController

@property (nonatomic, strong) SHCamera *camera;

+ (instancetype)qrCodeShareVC;

@end
