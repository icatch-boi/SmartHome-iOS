//
//  MsgFileManager.m
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import "MsgFileManager.h"
@interface MsgFileManager()
-(BOOL) checkTable;
@property sqlite3* msgDB;
@property NSString* fileTable;
@end

@implementation MsgFileManager

-(BOOL) checkTable
{
    NSString* checkSql = [NSString stringWithFormat:@"select * from %@", _fileTable];
    int ret = sqlite3_exec(_msgDB, checkSql.UTF8String, NULL, NULL, NULL);
    if (ret != SQLITE_OK) {
        //create table;
        NSString* createTableSql = [NSString stringWithFormat:@"create table %@(DateTime DATETIME PRIMARY KEY, FileHandle INTEGER, FileName VARCHAR, FileDuration INTEGER, Thumbnail BLOB, ThumbnailSize INTEGER)", _fileTable];
        ret = sqlite3_exec(_msgDB, createTableSql.UTF8String, NULL, NULL, NULL);
        if (ret != SQLITE_OK) {
            NSLog(@"do sql : %@ fail : %d", createTableSql, ret);
            NSLog(@"%@ table not exsit!",_fileTable);
            return NO;
        }
    }
    return YES;
}

-(instancetype) initWithDB:(sqlite3*)DB
{
    self = [super init];
    self.msgDB = DB;
    self.fileTable = kFileTableName;
    if(![self checkTable]) {
        return nil;
    }
    return self;
}
-(BOOL) checkDateInDatabaseWithDatetime:(NSString *)datetime
{
    NSString *dayMax = [NSString stringWithFormat:@"%@ %@", [datetime substringToIndex:@"yyyy-MM-dd".length], @"23:59:59"];
    NSString* querySql = [NSString stringWithFormat:@"select DateTime from %@ where DateTime between datetime('%@') and datetime('%@') order by DateTime DESC", _fileTable, datetime, dayMax];
     BOOL bRet = NO;
    
    sqlite3_stmt * stmt;
    int ret = sqlite3_prepare_v2(_msgDB, querySql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        sqlite3_finalize(stmt);
        NSLog(@"do sql : %@ fail : %d", querySql, ret);
        return bRet;
    }
   
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        bRet = YES;
    }
    sqlite3_finalize(stmt);
    //NSLog(@"check date[%@] in database : %@", datetime, bRet ? @"YES" : @"NO");
    return bRet;
}
-(NSArray*) getFileInfoWithStartTime:(NSString *)start andEndTime:(NSString *)end
{
    NSArray* resultArr = nil;
    NSString* querySql = [NSString stringWithFormat:@"select DateTime, FileHandle, FileName, FileDuration, ThumbnailSize from %@ where DateTime between datetime('%@') and datetime('%@') order by DateTime DESC", _fileTable, start, end];
//    NSLog(@"query filetable : %@", querySql);
    sqlite3_stmt * stmt;
    int ret = sqlite3_prepare_v2(_msgDB, querySql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        sqlite3_finalize(stmt);
        NSLog(@"do sql : %@ fail : %d", querySql, ret);
        return resultArr;
    }
    NSMutableArray* mArr = [NSMutableArray new];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        MsgFileInfo* info = [MsgFileInfo new];
        info.datetime = [NSString stringWithFormat:@"%s", sqlite3_column_text(stmt, 0)];
        info.handle = sqlite3_column_int(stmt, 1);
        info.name =  [NSString stringWithFormat:@"%s", sqlite3_column_text(stmt, 2)];
        info.duration = sqlite3_column_int(stmt, 3);
        info.thumnailSize = sqlite3_column_int(stmt, 4);
        [mArr addObject:info];
    }
    sqlite3_finalize(stmt);
    resultArr = [mArr copy];
    return resultArr;
}
-(BOOL)addFileInfos:(NSArray *)infos
{
    for(MsgFileInfo *info in infos) {
        [self addFileInfo:info];
    }
    return YES;
}
-(NSData* )getThumbnail:(int)hanle andDatetime:(NSString *)datetime
{
    NSString* querySql = [NSString stringWithFormat:@"select Thumbnail ThumnmailSize from %@ where DateTime = datetime('%@')",_fileTable, datetime];
    sqlite3_stmt* stmt;
    NSData* thumbnail = nil;
    int ret = sqlite3_prepare_v2(_msgDB, querySql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        sqlite3_finalize(stmt);
        NSLog(@"do sql : %@ fail : %d", querySql, ret);
        return thumbnail;
    }
    
    if(sqlite3_step(stmt) == SQLITE_ROW) {
        NSLog(@"thumbnail length : %d", sqlite3_column_bytes(stmt, 0));
        thumbnail = [NSData dataWithBytes:sqlite3_column_blob(stmt, 0) length:sqlite3_column_bytes(stmt, 0)];
    }
    return thumbnail;
}

-(BOOL) addFileInfo:(MsgFileInfo *)info
{
    NSString* insertSql = [NSString stringWithFormat:@"insert into %@ (DateTime, FileHandle, FileName, FileDuration, ThumbnailSize) VALUES (datetime('%@'), %zd, '%@', %zd, %zd)", _fileTable, info.datetime, info.handle, info.name, info.duration, info.thumnailSize];
    int ret = sqlite3_exec(_msgDB, insertSql.UTF8String, NULL, NULL, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do sql : %@ fail : %d", insertSql, ret);
        return NO;
    }
   // NSLog(@"do sql %@", insertSql);
    return YES;
}

-(BOOL) addThumbnail:(NSData *)thumbnail andThumbnailSize:(int)size withConditon:(MsgFileInfo *)info
{
    NSString* insertThumbnailSql = [NSString stringWithFormat:@"update %@ set ThumbnailSize = %d , Thumbnail= ? where DateTime = datetime('%@')", _fileTable, size, info.datetime];
    sqlite3_stmt * stmt;
    sqlite3_prepare_v2(_msgDB, insertThumbnailSql.UTF8String, -1, &stmt, NULL);
    sqlite3_bind_blob(stmt, 1, thumbnail.bytes, size, NULL);
    int ret = sqlite3_step(stmt);
    if(ret != SQLITE_DONE) {
        sqlite3_finalize(stmt);
        NSLog(@"do sql : %@ fail : %d", insertThumbnailSql, ret);
        return NO;
    }
    sqlite3_finalize(stmt);
    return YES;
}

-(NSData*) getThumbnail:(MsgFileInfo *)info
{
    NSString * getThumbnailSql = [NSString stringWithFormat:@"select Thumbnail, ThumbnailSize from %@ where DateTime = datetime('%@')", _fileTable, info.datetime];
    sqlite3_stmt* stmt;
    NSData* thumbnail = nil;
    int ret = sqlite3_prepare_v2(_msgDB, getThumbnailSql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        sqlite3_finalize(stmt);
        NSLog(@"do sql : %@ fail : %d", getThumbnailSql, ret);
        return thumbnail;
    }
    if(sqlite3_step(stmt) == SQLITE_ROW) {
        thumbnail = [NSData dataWithBytes:sqlite3_column_blob(stmt, 0) length:sqlite3_column_bytes(stmt, 0)];
    }
    sqlite3_finalize(stmt);
    return thumbnail;
}

-(BOOL) deleteFileWithFileInfo:(MsgFileInfo *)info
{
    NSString* deleteSql = [NSString stringWithFormat:@"delete from %@ where DateTime=datetime('%@')", _fileTable, info.datetime];
    int ret = sqlite3_exec(_msgDB, deleteSql.UTF8String, NULL, NULL, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do sql : %@ fail : %d", deleteSql, ret);
        return NO;
    }
    return YES;
}

-(BOOL) clearAllFile
{
    NSString* deleteAllSql = [NSString stringWithFormat:@"delete from %@", _fileTable];
    int ret = sqlite3_exec(_msgDB, deleteAllSql.UTF8String, NULL, NULL, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do sql : %@ fail : %d", deleteAllSql, ret);
        return NO;
    }
    return YES;
}

@end
