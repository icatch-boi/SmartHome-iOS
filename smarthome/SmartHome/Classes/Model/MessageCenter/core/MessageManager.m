//
//  MessageManager.m
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import "MessageManager.h"
#import <sqlite3.h>
@interface MessageManager()
@property NSString* dbName;
@property sqlite3* msgDB;
@property NSString* tableName;
-(BOOL) checkTable;
@end

@implementation MessageManager

-(instancetype) initWithDBName:(sqlite3 *)DB;
{
    self = [super init];
    self.tableName = kMsgTableName;
    self.msgDB = DB;
    if(![self checkTable]) {
        return nil;
    }
    return self;
}

-(BOOL) checkTable
{
    NSString* checkSql = [NSString stringWithFormat:@"select * from %@", _tableName];
    sqlite3_stmt * stmt;
    int ret = sqlite3_prepare_v2(_msgDB, checkSql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"check %@ table not exsit!", _tableName);
        
        sqlite3_finalize(stmt);
        //create table
        NSString* createSql = [NSString stringWithFormat:@"create table %@ (MsgIndex INTEGER PRIMARY KEY AUTOINCREMENT, MsgID INT NOT NULL, DevID VARCHAR NOT NULL, DateTime DATETIME NOT NULL, MsgType INT NOT NULL)", _tableName];
        ret = sqlite3_exec(_msgDB, createSql.UTF8String, NULL, NULL, NULL);
        NSLog(@"%@",createSql);
        if(ret != SQLITE_OK) {
            NSLog(@"do sql : %@ fail : %s", createSql, sqlite3_errstr(ret));
            return NO;
        }
        //insert some msg for test
    }
#if 0 //假数据
    NSString *cntSql = [NSString stringWithFormat:@"select count(*) from %@", _tableName];
    ret = sqlite3_prepare_v2(_msgDB, cntSql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        sqlite3_finalize(stmt);
        return NO;
    }
    int cnt = 0;
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        cnt = sqlite3_column_int(stmt, 0);
    }
    sqlite3_finalize(stmt);
    if(cnt == 0) {
        int  i = 0;
        int type = 100;
        for (i = 0; i < 5; i ++) {
            if( i % 2 == 0) {
                type = 100;
            } else {
                type = 201;
            }
            
            NSString* sql = [NSString stringWithFormat:@"insert into %@ (MsgID, DevID, DateTime, MsgType) VALUES (%d, '%s', datetime('%s'), %d)", _tableName, i, "chenjian", "2018-03-26 19:52:00", type ];
            
            ret = sqlite3_exec(_msgDB, sql.UTF8String, NULL, NULL, NULL);
            if(ret != SQLITE_OK) {
                NSLog(@"do sql %@ err: %s-ret = %d", sql, sqlite3_errstr(ret), ret);
                return NO;
            }
        }
    }
#endif
    return YES;
}

-(NSArray <MessageInfo*> *) getMessageWithIndex:(int) index andCount :(int)count
{
   // NSString* sql = [NSString stringWithFormat:@"select * from %s where msgIndex between %d and %d", _tableName.UTF8String, index, index+count];
    NSString* sql = [NSString stringWithFormat:@"select * from %s where MsgIndex >= %d order by MsgIndex DESC LIMIT %d ", _tableName.UTF8String, index, count];
    sqlite3_stmt* stmt = nil;
    int ret = sqlite3_prepare_v2(_msgDB, sql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do %s err: %s",sql.UTF8String, sqlite3_errstr(ret));
        return nil;
    }
    NSMutableArray* mMsgArr = [NSMutableArray new];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int msgIndex = sqlite3_column_int(stmt, 0);
        int msgID = sqlite3_column_int(stmt, 1);
        const char* devID = (const char*)sqlite3_column_text(stmt, 2);
        const char* dateTime = (const char*)sqlite3_column_text(stmt, 3);
        int msgType = sqlite3_column_int(stmt, 4);
        MessageInfo * info = [[MessageInfo alloc] initWithIndex:msgIndex andMsgID:msgID andDevID:[NSString stringWithFormat:@"%s", devID] andDatetime:[NSString stringWithFormat:@"%s", dateTime] andMsgType:msgType];
        [info debug];
        [mMsgArr addObject:info];
    }
    NSArray* msgArr = [mMsgArr copy];
    return msgArr;
}

-(BOOL) addMessage:(MessageInfo *)info
{
    //check msg exsit ?
    NSString * querySql = [NSString stringWithFormat:@"select DateTime from %s where DateTime = datetime('%s')", _tableName.UTF8String, [info getMsgDatetime].UTF8String];
    sqlite3_stmt * stmt = nil;
    int ret = sqlite3_prepare_v2(_msgDB, querySql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do sql : %s err : %s", querySql.UTF8String, sqlite3_errstr(ret));
        return NO;
    }
    if(sqlite3_step(stmt) == SQLITE_ROW) {
        NSLog(@"this record is exsit !");
        return YES;
    }
    //insert msg
    NSString * insertSql = [NSString stringWithFormat:@"insert into %@ (MsgID, DevID, DateTime, MsgType) values (%d, '%@', datetime('%@'), %d)", _tableName, [info getMsgID], [info getDevID], [info getMsgDatetime], [info getMsgType]];
    ret = sqlite3_exec(_msgDB, insertSql.UTF8String, NULL, NULL, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do sql : %s err : %s", insertSql.UTF8String, sqlite3_errstr(ret));
        return NO;
    }
    return YES;
}

-(BOOL) deleteMessage:(MessageInfo *)info
{
    NSString* deleteSql = [NSString stringWithFormat:@"delete from %@ where MsgIndex=%d", _tableName, [info getMsgIndex]];
    int ret = sqlite3_exec(_msgDB, deleteSql.UTF8String, NULL, NULL, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do sql : %@ err : %s", deleteSql, sqlite3_errstr(ret));
        return NO;
    }
    return YES;
}

-(BOOL) clearAllMessage
{
    NSString* sql = [NSString stringWithFormat:@"delete from %@", _tableName];
    int ret = sqlite3_exec(_msgDB, sql.UTF8String, NULL, NULL, NULL);
    if(ret != SQLITE_OK) {
        NSLog(@"do sql : %@ err : %s", sql, sqlite3_errstr(ret));
        return NO;
    }
    return YES;
}

-(int) getMessageCount
{
    NSString* sql = [NSString stringWithFormat:@"select count(*) as msgCnt from %@", _tableName];
    sqlite3_stmt* stmt;
    int cnt = -1;
    int ret = sqlite3_prepare_v2(_msgDB, sql.UTF8String, -1, &stmt, NULL);
    if(ret != SQLITE_OK) {
        sqlite3_finalize(stmt);
        NSLog(@"do sql : %@ err : %s", sql, sqlite3_errstr(ret));
        return cnt;
    }
    
    if(sqlite3_step(stmt) == SQLITE_ROW) {
        cnt = sqlite3_column_int(stmt, 0);
    }
    sqlite3_finalize(stmt);
    return cnt;
}

@end
