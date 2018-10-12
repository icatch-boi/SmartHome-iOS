//
//  ViewController.h
//  SmartHome
//
//  Created by ZJ on 2017/4/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SHSinglePreviewVCDelegate <NSObject>

- (void)disconnectHandle;

@end

@interface SHSinglePreviewVC : UIViewController

@property (nonatomic, copy) NSString *cameraUid;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSDictionary *notification;
@property (nonatomic, getter=isForeground) BOOL foreground;

@property (nonatomic, weak) id <SHSinglePreviewVCDelegate> delegate;

@end

