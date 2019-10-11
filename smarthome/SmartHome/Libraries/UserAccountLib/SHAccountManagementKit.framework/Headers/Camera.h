//
//  Camera.h
//  SHAccountManagementKit
//
//  Created by 江果 on 06/02/2018.
//  Copyright © 2018 iCatchTek. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Camera : NSObject

@property(nonatomic, readonly) NSString * _Nonnull id;
@property(nonatomic, readonly) NSString * _Nonnull ownerId;
@property(nonatomic, readonly) NSString * _Nonnull cover;
@property(nonatomic, readonly) NSString * _Nonnull time;

@property(nonatomic, readonly) NSString * _Nullable uid;
@property(nonatomic, readonly) int type;
@property(nonatomic, readonly) int operable;//access
@property(nonatomic, readonly) NSString * _Nullable name;
@property(nonatomic, readonly) NSString * _Nullable memoname;
@property(nonatomic, readonly) NSString * _Nullable devicepassword;
@property(nonatomic, readonly) int status;

@property (nonatomic, copy) NSString * _Nullable hwversionid;
@property (nonatomic, copy) NSString * _Nullable versionid;

-(instancetype _Nonnull )initWithData:(NSDictionary * _Nonnull )dict;

-(instancetype _Nonnull )initWithId:(NSString *_Nonnull)cameraId
                            andTime:(NSString *_Nonnull)time
                         andOwnerId:(NSString *_Nonnull)ownerId
                           andCover:(NSString *_Nonnull)cover
                            andUUID:(NSString *_Nullable)uuid
                            andType:(int)type
                         andOperate:(int)operate
                            andName:(NSString *_Nonnull)name
                         andMemname:(NSString *_Nonnull)memname
                          andStatus:(int)status
                  andDevicePassword:(NSString* _Nullable)devicePassword;

- (void)debug;
@end
