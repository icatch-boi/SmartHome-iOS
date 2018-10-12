//
//  SHAPModeViewController.h
//  SmartHome
//
//  Created by ZJ on 2017/12/15.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAPModeViewController : UIViewController

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) BOOL directEnterAPMode;
@property (nonatomic, copy) NSString *wifiSSID;
@property (nonatomic, copy) NSString *wifiPWD;
@property (nonatomic, copy) NSString *devicePWD;

@end
