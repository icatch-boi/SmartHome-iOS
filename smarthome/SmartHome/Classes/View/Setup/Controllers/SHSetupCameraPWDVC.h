//
//  SHSetupCameraPWDVC.h
//  SmartHome
//
//  Created by ZJ on 2017/12/22.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHSetupCameraPWDVC : UIViewController

//@property (nonatomic, copy) NSString *cameraUid;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSString *wifiSSID;
@property (nonatomic, copy) NSString *wifiPWD;

@end
