//
//  SHCamera.m
//  SmartHome
//
//  Created by ZJ on 2017/4/13.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHCamera.h"

@implementation SHCamera

@dynamic thumbnail;
@dynamic cameraUid;
@dynamic cameraName;
@dynamic pvTime;
@dynamic pbTime;
@dynamic createTime;
@dynamic videoFormat;
@dynamic audioFormat;
#if USE_ENCRYP
@dynamic cameraToken;
@dynamic cameraUidToken;
#endif
@dynamic devicePassword;
//@dynamic securitySettings;
@dynamic mapToTutk;
@dynamic id;
@dynamic operable;

#if USE_ENCRYP
- (NSString *)cameraUid {
    return [[SHQRManager sharedQRManager] getUID:self.cameraToken];
}
#endif

@end
