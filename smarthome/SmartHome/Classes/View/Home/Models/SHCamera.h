//
//  SHCamera.h
//  SmartHome
//
//  Created by ZJ on 2017/4/13.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SHVideoFormat;
@class SHAudioFormat;
@interface SHCamera : NSManagedObject

@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSString *cameraUid;
@property (nonatomic, retain) NSString *cameraName;
@property (nonatomic, retain) NSString *pvTime;
@property (nonatomic, retain) NSString *pbTime;
@property (nonatomic, retain) NSString *createTime;
@property (nonatomic, retain) SHVideoFormat *videoFormat;
@property (nonatomic, retain) SHAudioFormat *audioFormat;
#if USE_ENCRYP
@property (nonatomic, retain) NSString *cameraToken;
@property (nonatomic, retain) NSString *cameraUidToken;
#endif
@property (nonatomic, retain) NSString *devicePassword;
//@property (nonatomic) BOOL securitySettings;
@property (nonatomic) BOOL mapToTutk;
@property (nonatomic, retain) NSString *id;
@property (nonatomic) int operable; //1 代表拥有者权限

@end
