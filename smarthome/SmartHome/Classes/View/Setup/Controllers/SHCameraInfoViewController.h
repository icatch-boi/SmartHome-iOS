//
//  SHCameraInfoViewController.h
//  SmartHome
//
//  Created by ZJ on 2017/12/12.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHCameraInfoViewController : UIViewController

@property (nonatomic, copy) NSString *cameraUid;
@property (nonatomic, copy) NSString *devicePWD;
@property (nonatomic, copy) NSString *wifiSSID;
@property (nonatomic, copy) NSString *wifiPWD;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
