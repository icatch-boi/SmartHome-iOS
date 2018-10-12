//
//  SHFileDownloadTVC.h
//  SmartHome
//
//  Created by ZJ on 2017/6/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SHFileTable.h"

@interface SHFileDownloadTVC : UITableViewController

@property (nonatomic) void (^downloadCompleteBlock)();

@property (nonatomic, copy) NSString *cameraUid;

@end
