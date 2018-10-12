//
//  SHDBAccess.h
//  SmartHome
//
//  Created by ZJ on 2017/5/24.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHFileThumbnail.h"

@interface SHDatabase : NSObject

+ (instancetype)databaseWithDatabaseName:(NSString *)name;
- (BOOL)insertToDataBaseWithFileThumbnail:(SHFileThumbnail *)thumbFile;
- (BOOL)deleteFromDataBaseWithFileHandle:(NSInteger)fileHandle;
- (NSArray *)queryFromDataBaseWithFileHandle:(NSInteger)fileHandle;
- (BOOL)containsDataWithFileHandle:(NSInteger)fileHandle;
- (void)closeDatabase;

@end
