//
//  SHDBAccess.m
//  SmartHome
//
//  Created by ZJ on 2017/5/24.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHDatabase.h"
#import <sqlite3.h>

#define kSuffix @".db"
@interface SHDatabase ()

@property (nonatomic, copy) NSString *databaseName;

@end

sqlite3* database;

@implementation SHDatabase

+ (NSString *)pathWithDatabaseName:(NSString *)databaseName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *documentDirectory = [paths lastObject];
    return [documentDirectory stringByAppendingPathComponent:databaseName];
}

- (BOOL)createEditableDatabaseWithName:(NSString *)databaseName
{
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 数据库文件路径
    NSString *writableDB = [SHDatabase pathWithDatabaseName:databaseName];
    // 文件是否存在
    success = [fileManager fileExistsAtPath:writableDB];
    
    return success;
}

+ (instancetype)databaseWithDatabaseName:(NSString *)name {
    if (![name hasSuffix:kSuffix]) {
        name = [name stringByAppendingString:kSuffix];
    }
    
    SHDatabase *db = [[self alloc] initWithDatabaseName:name];
//    db.databaseName = name;
    
    return db;
}

- (BOOL)openDatabase {
    // 数据库路径
    NSString *path = [SHDatabase pathWithDatabaseName:_databaseName];
    // 是否打开成功
#if 0
    int retVal = sqlite3_open([path UTF8String], &database);
#else
    // fixes: sqlite3.dylib: illegal multi-threaded access to database connection
    sqlite3_shutdown();
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    sqlite3_initialize();
    
    NSLog(@"isThreadSafe %d", sqlite3_threadsafe());
    int retVal = sqlite3_open_v2(path.UTF8String, &database, SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, NULL);
#endif
    if (retVal == SQLITE_OK)
    {
        NSLog(@"Opening Database");
    }
    else
    {
        // 打开数据库失败
        sqlite3_close(database);
#if DEBUG
        NSAssert1(0, @"Failed to open database: '%s'.", sqlite3_errmsg(database));
#else
        NSLog(@"Failed to open database: '%s'.", sqlite3_errmsg(database));
#endif
    }
    
    return retVal == SQLITE_OK ? YES : NO;
}

- (void)closeDatabase
{
    if (sqlite3_close(database) != SQLITE_OK) {
#if DEBUG
        NSAssert1(0, @"Failed to close database: '%s'.", sqlite3_errmsg(database));
#else
        NSLog(@"Failed to open database: '%s'.", sqlite3_errmsg(database));
#endif
    }
}

- (instancetype)initWithDatabaseName:(NSString *)databaseName {
    self = [super init];
    
    if (self) {
        self.databaseName = databaseName;
        [self initializeDatabase];
    }
    
    return self;
}

- (BOOL)initializeDatabase {
    if ([self createEditableDatabaseWithName:_databaseName]) {
        return [self openDatabase];
    }
    
    NSString *sql = @"CREATE TABLE IF NOT EXISTS main.SHFileThumbnail (ID INTEGER PRIMARY KEY AUTOINCREMENT, fileHandle INTEGER, fileType INTEGER, fileName TEXT, createDate TEXT, createTime TEXT, motion INTEGER, duration INTEGER, thumbSize INTEGER, thumb BLOB)";
    
    if ([self openDatabase]) {
        char *errMsg;
        
        int retVal = sqlite3_exec(database, sql.UTF8String, NULL, NULL, &errMsg);
        if (retVal != SQLITE_OK) {
            NSLog(@"error when creating db table: %s", errMsg);
        } else {
            NSLog(@"success to creating db table");
        }
        
        return retVal == SQLITE_OK ? YES : NO;
    }
    
    return NO;
}

- (BOOL)insertToDataBaseWithFileThumbnail:(SHFileThumbnail *)thumbFile {
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO main.SHFileThumbnail (fileHandle, fileType, fileName, createDate, createTime, motion, duration, thumbSize, thumb) VALUES(\"%zd\",\"%zd\",\"%@\",\"%@\",\"%@\",\"%zd\",\"%zd\",\"%zd\",?)", thumbFile.fileHandle, thumbFile.fileType, thumbFile.fileName, thumbFile.createDate, thumbFile.createTime, thumbFile.motion, thumbFile.duration, thumbFile.thumbnailSize];
    
    sqlite3_stmt *statement;
    
    const char *insert_stmt = [sql UTF8String];
    
    sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
    sqlite3_bind_blob(statement, 1, thumbFile.thumbnail.bytes, (int)thumbFile.thumbnailSize, NULL);
    int retVal = sqlite3_step(statement);
    
    if (retVal == SQLITE_DONE) {
        NSLog(@"已存储到数据库");
    } else {
        NSLog(@"保存失败");
    }
    
    sqlite3_finalize(statement);

    return retVal == SQLITE_DONE ? YES : NO;
}

- (BOOL)deleteFromDataBaseWithFileHandle:(NSInteger)fileHandle {
    NSString *sql = [NSString stringWithFormat:@"delete from main.SHFileThumbnail where SHFileThumbnail.fileHandle = %zd", fileHandle];
    
    sqlite3_stmt *statement;

    const char *delete_stmt = [sql UTF8String];
    
    sqlite3_prepare_v2(database, delete_stmt, -1, &statement, NULL);
    int retVal = sqlite3_step(statement);
    
    if (retVal == SQLITE_DONE) {
        NSLog(@"已删除数据");
    } else {
        NSLog(@"删除失败");
    }
    
    sqlite3_finalize(statement);

    return retVal == SQLITE_DONE ? YES : NO;
}

- (NSArray *)queryFromDataBaseWithFileHandle:(NSInteger)fileHandle {
    // 查询语句
    NSString *sql = [NSString stringWithFormat:@"SELECT SHFileThumbnail.fileType, SHFileThumbnail.fileName, \
                           SHFileThumbnail.createDate, SHFileThumbnail.createTime, SHFileThumbnail.motion, SHFileThumbnail.duration, \
                           SHFileThumbnail.thumbSize, SHFileThumbnail.thumb FROM SHFileThumbnail WHERE SHFileThumbnail.fileHandle = %zd", fileHandle];
    
    // 将sql文本转换成一个准备语句
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sql.UTF8String, -1, &statement, NULL);
    // 装查询结果的可变数组
    NSMutableArray *arrayM = [NSMutableArray array];
    // 结果状态为OK时，开始取出每条数据
    if ( sqlResult == SQLITE_OK) {
        NSLog(@"Select succeed with database.");
        // 只要还有下一行，就取出数据。
        while (sqlite3_step(statement) == SQLITE_ROW) {
            SHFileThumbnail *thumbFile = [[SHFileThumbnail alloc] init];
            
            char *fileName = (char *)sqlite3_column_text(statement, 1);
            char *createDate = (char *)sqlite3_column_text(statement, 2);
            char *createTime = (char *)sqlite3_column_text(statement, 3);
            const void  *thumb = (const void  *)sqlite3_column_blob(statement, 7);
            
            thumbFile.fileHandle = fileHandle;
            thumbFile.fileType = sqlite3_column_int(statement, 0);
            thumbFile.fileName = [self stringWithCharString:fileName];
            thumbFile.createDate = [self stringWithCharString:createDate];
            thumbFile.createTime = [self stringWithCharString:createTime];
            thumbFile.motion = sqlite3_column_int(statement, 4);
            thumbFile.duration = sqlite3_column_int64(statement, 5);
            thumbFile.thumbnailSize = sqlite3_column_int(statement, 6);
            thumbFile.thumbnail = [NSData dataWithBytes:thumb length:thumbFile.thumbnailSize];
            
            [arrayM addObject:thumbFile];
        }
        // 完成后释放prepare创建的准备语句
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with database:");
        NSLog(@"%d",sqlResult);
    }
    
    return arrayM.copy;
}

- (BOOL)containsDataWithFileHandle:(NSInteger)fileHandle {
    BOOL contains = NO;
    
    // 查询语句
    NSString *sql = [NSString stringWithFormat:@"SELECT SHFileThumbnail.fileType, SHFileThumbnail.fileName, \
                     SHFileThumbnail.createDate, SHFileThumbnail.createTime, SHFileThumbnail.motion, SHFileThumbnail.duration, \
                     SHFileThumbnail.thumbSize, SHFileThumbnail.thumb FROM SHFileThumbnail WHERE SHFileThumbnail.fileHandle = %zd", fileHandle];
    
    // 将sql文本转换成一个准备语句
    sqlite3_stmt *statement;
    int sqlResult = sqlite3_prepare_v2(database, sql.UTF8String, -1, &statement, NULL);

    // 结果状态为OK时，开始取出每条数据
    if ( sqlResult == SQLITE_OK) {
        NSLog(@"Select succeed with database.");

        // 只要还有下一行，就取出数据。
        while (sqlite3_step(statement) == SQLITE_ROW) {
            contains = YES;
            NSLog(@"Contains member of fileHandle = %zd.", fileHandle);
            break;
        }
        // 完成后释放prepare创建的准备语句
        sqlite3_finalize(statement);
    } else {
        NSLog(@"Problem with database:");
        NSLog(@"%d",sqlResult);
    }

    return contains;
}

/** C字符串转换OC字符串 */
- (NSString *) stringWithCharString:(char *)string
{
    return (string) ? [NSString stringWithUTF8String:string] : @"";
}

@end
