//
//  SHSaveSupportedProperty.m
//  SmartHome
//
//  Created by ZJ on 2017/7/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSaveSupportedProperty.h"

@implementation SHSaveSupportedProperty

- (NSMutableDictionary *)sspDict {
    if (_sspDict == nil) {
        _sspDict = [NSMutableDictionary dictionary];
    }
    
    return _sspDict;
}

- (BOOL)saveToPath:(NSString *)path {
    NSString *rootDir = [SHTool createMediaDirectoryWithPath:path][0];
    NSString *name = [rootDir stringByAppendingPathComponent:@"CameraSupportedProperty.plist"];
    BOOL retVal = [self.sspDict writeToFile:name atomically:YES];
    SHLogInfo(SHLogTagAPP, @"saveToPath retVal: %d", retVal);
    
    return retVal;
}

- (void)readFromPath:(NSString *)path {
    NSString *rootDir = [SHTool createMediaDirectoryWithPath:path][0];
    NSString *name = [rootDir stringByAppendingPathComponent:@"CameraSupportedProperty.plist"];
    
    [self cleanCache];
    self.sspDict = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:name]];
}

- (void)cleanCache {
    [self.sspDict removeAllObjects];
}

- (BOOL)containsKey:(NSString *)key {
    return [self.sspDict.allKeys containsObject:key];
}

@end
