//
//  SHUserAccountInfoTVC.h
//  SmartHome
//
//  Created by ZJ on 2018/3/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHUserAccountInfoTVC : UITableViewController

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (instancetype)userAccountInfoTVC;

@end
