// DBManager.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by sa on 2018/3/27 下午7:29.
    

#import "DBManager.h"
#import "DBWrapper.h"

@implementation DBManager
NSMutableDictionary *getDBContainer()
{
    static NSMutableDictionary *DBContainer = nil;
    if(DBContainer == nil) {
        DBContainer = [NSMutableDictionary new];
    }
    return DBContainer;
}

+ (sqlite3*) openDBWithName:(NSString*)name
{
    DBWrapper *dbWrapper = [getDBContainer() objectForKey:name];
    if(dbWrapper == nil) {
        dbWrapper = [DBWrapper new];
        sqlite3* DBInstance = NULL;
        int ret = sqlite3_open(name.UTF8String, &DBInstance);
        if(ret != SQLITE_OK) {
            NSLog(@"open db : %@ fail, ret = %d, reason : %s", name, ret, sqlite3_errstr(ret));
            return NULL;
        }
        dbWrapper.DB = DBInstance;
    }
    [getDBContainer() setObject:dbWrapper forKey:name];
    return dbWrapper.DB;
}

+ (void) closeDBWithName:(NSString *)name
{
    DBWrapper* dbWrapper = [getDBContainer() objectForKey:name];
    if(dbWrapper != nil) {
        sqlite3_close(dbWrapper.DB);
        dbWrapper.DB = NULL;
        [getDBContainer() removeObjectForKey:name];
    }
}

+ (void) closeAllDB
{
    for(DBWrapper* dbWrapper in getDBContainer()) {
        if( dbWrapper != nil) {
            sqlite3_close(dbWrapper.DB);
            dbWrapper.DB = NULL;
        }
    }
    [getDBContainer() removeAllObjects];
}

+ (void)deleteDBWithName:(NSString *)name
{
    DBWrapper *dbWrapper = [getDBContainer() objectForKey:name];
    if(dbWrapper != nil) {
        sqlite3_close(dbWrapper.DB);
        [getDBContainer() removeObjectForKey:name];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:name]) {
        [fileManager removeItemAtPath:name error:nil];
    }
    NSLog(@"delete db : %@", name);
}

@end
