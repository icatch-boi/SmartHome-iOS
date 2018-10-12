//
//  SHShareHomeTVC.h
//  SmartHome
//
//  Created by ZJ on 2018/3/7.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHShareHomeTVC : UITableViewController

@property (nonatomic, strong) SHCamera *camera;

+ (instancetype)shareHomeViewController;

@end
