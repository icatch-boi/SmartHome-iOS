//
//  SHMessagesListTVC.h
//  SmartHome
//
//  Created by ZJ on 2018/3/14.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHMessagesListTVC : UITableViewController

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (instancetype)messageListTVC;

@end
