//
//  SHFileTable.m
//  SmartHome
//
//  Created by ZJ on 2017/5/5.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHFileTable.h"

@implementation SHFileTable

+ (instancetype)fileTableWithFileCreateDate:(NSString *)fileCreateDate andFileStorage:(unsigned long long)fileStorage andFileList:(vector<ICatchFile>)fileList {
    SHFileTable *table = [[SHFileTable alloc] init];
    
    table.fileCreateDate = fileCreateDate;
    table.fileStorage = fileStorage;
    table.fileList = fileList;
    
    return table;
}

@end
