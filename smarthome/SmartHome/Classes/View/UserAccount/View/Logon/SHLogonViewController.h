//
//  SHLogonViewController.h
//  SmartHome
//
//  Created by ZJ on 2018/3/6.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHLogonViewController : UIViewController

@property (nonatomic, copy) NSString *email;
@property (nonatomic, assign) BOOL resetPWD;

+ (instancetype)logonViewController;

@end
