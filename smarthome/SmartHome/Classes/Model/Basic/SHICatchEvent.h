//
//  SHICatchEvent.h
//  SmartHome
//
//  Created by ZJ on 2017/6/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHICatchEvent : NSObject

@property (nonatomic, assign) int eventID;
@property (nonatomic, assign) int sessionID;

@property (nonatomic, assign) int intValue1;
@property (nonatomic, assign) int intValue2;
@property (nonatomic, assign) int intValue3;

@property (nonatomic, assign) double doubleValue1;
@property (nonatomic, assign) double doubleValue2;
@property (nonatomic, assign) double doubleValue3;

@property (nonatomic, copy) NSString* stringValue1;
@property (nonatomic, copy) NSString* stringValue2;
@property (nonatomic, copy) NSString* stringValue3;

@property (nonatomic) ICatchFile fileValue;

+ (instancetype)iCatchEvent:(ICatchEvent *)icatchEvt;

@end
