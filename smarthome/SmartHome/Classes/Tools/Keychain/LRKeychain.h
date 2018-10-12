//
//  LRKeychain.h
//  LazyReader
//
//  Created by 颜镜圳 on 16/9/7.
//  Copyright © 2016年 颜镜圳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface LRKeychain : NSObject

+ (void)addKeychainData:(id)data forKey:(NSString *)key;///< 添加数据
+ (id)getKeychainDataForKey:(NSString *)key;///< 根据key获取相应的数据
+ (void)deleteKeychainDataForKey:(NSString *)key;///< 删除数据

@end
