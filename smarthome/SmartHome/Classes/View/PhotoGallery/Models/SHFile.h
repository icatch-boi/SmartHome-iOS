//
//  SHFile.h
//  SmartHome
//
//  Created by ZJ on 2017/6/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHFile : NSObject

@property (nonatomic) NSString *uid;
@property (nonatomic) smarthome::ICatchFile f;


+ (instancetype)fileWithUid:(NSString*)uid file:(ICatchFile)f;

@end
