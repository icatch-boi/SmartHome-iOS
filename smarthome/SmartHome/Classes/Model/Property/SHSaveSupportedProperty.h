//
//  SHSaveSupportedProperty.h
//  SmartHome
//
//  Created by ZJ on 2017/7/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHSaveSupportedProperty : NSObject

@property (nonatomic, strong) NSMutableDictionary *sspDict;

- (BOOL)saveToPath:(NSString *)path;
- (void)readFromPath:(NSString *)path;
- (void)cleanCache;
- (BOOL)containsKey:(NSString *)key;

@end
