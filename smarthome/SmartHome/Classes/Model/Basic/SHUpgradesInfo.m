// SHUpgradesInfo.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2019/3/13 11:34 AM.
    

#import "SHUpgradesInfo.h"
#import "SHNetworkManagerHeader.h"

@interface SHUpgradesInfo ()

@property (nonatomic, copy) NSString *versionid;
@property (nonatomic, copy) NSString *html_description;
@property (nonatomic, copy) NSString *expires;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, copy) NSNumber *size;
@property (nonatomic, strong) NSArray<NSString *> *url;
@property (nonatomic, strong) NSArray<NSString *> *name;
@property (nonatomic, copy) NSString *localVersion;

@end

@implementation SHUpgradesInfo

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

+ (instancetype)upgradesInfoWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"description"]) {
        [self setValue:value ? value : @"" forKey:@"html_description"];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

+ (void)checkUpgradesWithCameraObj:(SHCameraObject *)shCameraObj completion:(void (^)(BOOL hint, SHUpgradesInfo * _Nullable info))completion {
    if (shCameraObj.camera.operable != 1) {
        if (completion) {
            completion(NO, nil);
        }
        
        SHLogWarn(SHLogTagAPP, @"Current user isn't device owner.");
        return;
    }
    
    if (shCameraObj.cameraProperty.upgradesInfo != nil) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    
    BOOL support = [shCameraObj.controler.propCtrl deviceSupportUpgradeWithCamera:shCameraObj];
    if (support == NO) {
        if (completion) {
            completion(NO, nil);
        }
        
        SHLogWarn(SHLogTagAPP, @"Device no support upgrade.");
        return;
    }
    
    [self getDeviceUpgradeInfoWithCameraObj:shCameraObj completion:completion];
}

+ (void)getDeviceUpgradeInfoWithCameraObj:(SHCameraObject *)shCameraObj completion:(void (^)(BOOL hint, SHUpgradesInfo * _Nullable info))completion {
    [[NSOperationQueue new] addOperationWithBlock:^{
        shared_ptr<ICatchCameraVersion> version = [shCameraObj.controler.propCtrl retrieveCameraVersionWithCamera:shCameraObj];

        [[SHNetworkManager sharedNetworkManager] getDeviceUpgradesInfoWithCameraID:shCameraObj.camera.id completion:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"Get device upgrades info is success: %d", isSuccess);
            
            if (isSuccess) {
                // "31413.23126.2254",
                SHLogInfo(SHLogTagAPP, @"DeviceUpgradesInfo: %@", result);
                
                NSDictionary *info = result;
                if (info == nil || info.count <= 0) {
                    SHLogError(SHLogTagAPP, @"upgrades info is nil.");
                    if (completion) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            completion(NO, nil);
                        }];
                    }
                    return;
                }
                
                SHUpgradesInfo *upInfo = [self upgradesInfoWithDict:info];
                upInfo.localVersion = [NSString stringWithFormat:@"%s", version->getFirmwareVer().c_str()];

                BOOL need = [self checkWhetherNeedUpgrades:upInfo.localVersion remoteVersion:upInfo.versionid];
                
                if (completion) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        completion(need, upInfo);
                    }];
                }
                
                upInfo.needUpgrade = need;
                shCameraObj.cameraProperty.upgradesInfo = upInfo;
            } else {
                if (completion) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        completion(NO, nil);
                    }];
                }
            }
        }];
    }];
}

+ (BOOL)checkWhetherNeedUpgrades:(NSString *)currentVersion remoteVersion:(NSString *)remoteVersion {
    if (currentVersion == nil || currentVersion.length <= 0 || remoteVersion == nil || remoteVersion.length <= 0) {
        return NO;
    }
    
    // FIXME: -- for test
//    currentVersion = @"31368.23224.2245";
    
    NSArray *currentVers = [currentVersion componentsSeparatedByString:@"."];
    NSArray *remoteVers = [remoteVersion componentsSeparatedByString:@"."];
    
    if (currentVers == nil || currentVers.count <= 0 || remoteVers == nil || remoteVers.count <= 0) {
        return NO;
    }
    
    if ([currentVers.firstObject integerValue] > [remoteVers.firstObject integerValue]) {
        return NO;
    }
    
    if ([currentVers.firstObject integerValue] < [remoteVers.firstObject integerValue]) {
        return YES;
    }
    
    if ([currentVers[1] integerValue] > [remoteVers[1] integerValue]) {
        return NO;
    }
    
    if ([currentVers[1] integerValue] < [remoteVers[1] integerValue]) {
        return YES;
    }
    
    if ([currentVers.lastObject integerValue] > [remoteVers.lastObject integerValue]) {
        return NO;
    }
    
    if ([currentVers.lastObject integerValue] < [remoteVers.lastObject integerValue]) {
        return YES;
    }
    
    return NO;
}

+ (NSAttributedString *)upgradesAlertViewMessageWithInfo:(SHUpgradesInfo *)info {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"kFWUpgradeDescription", nil), info.versionid, [DiskSpaceTool humanReadableStringFromBytes:[info.size longLongValue]]];
    
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];
    
    NSMutableAttributedString *description = [[NSMutableAttributedString alloc] initWithData:[info.html_description dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)} documentAttributes:nil error:nil];
    
    [description deleteCharactersInRange:NSMakeRange(description.length - 1, 1)];
    
    [attributedMessage appendAttributedString:description.copy];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentLeft;
    paragraph.lineSpacing = 12;
    
    [attributedMessage setAttributes:@{NSParagraphStyleAttributeName:paragraph, NSFontAttributeName: [UIFont systemFontOfSize:14.0]} range:NSMakeRange(0, attributedMessage.length)];
    
    return attributedMessage.copy;
}

+ (NSAttributedString *)upgradesAlertViewTitle {
    NSString *title = NSLocalizedString(@"kFWUpdateTitle", nil);
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
    
    NSMutableParagraphStyle *titleParagraph = [[NSMutableParagraphStyle alloc] init];
    titleParagraph.alignment = NSTextAlignmentCenter;
    titleParagraph.paragraphSpacingBefore = -5;
    [attributedTitle setAttributes:@{NSParagraphStyleAttributeName:titleParagraph, NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]} range:NSMakeRange(0, attributedTitle.length)];
    
    return attributedTitle.copy;
}

@end
