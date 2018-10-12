//
//  SHFileTable.h
//  SmartHome
//
//  Created by ZJ on 2017/5/5.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHFileTable : NSObject

@property (nonatomic, copy) NSString *fileCreateDate;
@property (nonatomic) vector<ICatchFile> fileList;
@property (nonatomic) unsigned long long fileStorage;

+ (instancetype)fileTableWithFileCreateDate:(NSString *)fileCreateDate andFileStorage:(unsigned long long)fileStorage andFileList:(vector<ICatchFile>)fileList;

@end
