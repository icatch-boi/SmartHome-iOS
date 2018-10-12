//
//  SHSettingProperty.h
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHSettingProperty : NSObject

+ (instancetype)settingPropertyWithControl:(Control *)control;
- (void)addProperty:(int)propertyId withIntValue:(int)intValue;
- (void)addProperty:(int)propertyId withStringValue:(NSString*)stringValue;
- (BOOL)submit;
- (ICatchTransProperty *)createSetProperty:(int)propertyId withIntValue:(int)intValue;
- (ICatchTransProperty *)createSetProperty:(int)propertyId withStringValue:(NSString*)stringValue;

@end
