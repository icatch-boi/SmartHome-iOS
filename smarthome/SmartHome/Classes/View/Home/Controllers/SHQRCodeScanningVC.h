//
//  SHQRCodeScanningVC.h
//  SmartHome
//
//  Created by ZJ on 2017/4/13.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SGQRCodeScanningVC.h"
#import "SGQRCode.h"

@interface SHQRCodeScanningVC : SGQRCodeScanningVC

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) BOOL isStandardMode;

@end
