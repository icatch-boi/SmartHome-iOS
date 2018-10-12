//
//  MessageCenter.m
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import "MessageCenter.h"
#import "MessageManager.h"
#import "MsgFileManager.h"
#import "DBManager.h"
#import "TimeHelper.h"
#import <sqlite3.h>
#import <time.h>

@interface MessageCenter()
@property (strong) NSString *cusName;
@property id <MSGNetWorkProtocol> networkDelegate;
@property MessageManager * msgManager;
@property MsgFileManager * fileManager;
@property NSMutableDictionary *visitedDatetimeDict;
@end

@implementation MessageCenter

static NSTimeInterval intervalSec = 60;
+ (instancetype)MessageCenterWithName:(NSString *)name andMsgDelegate:(id<MSGNetWorkProtocol>)networkDelegate
{
    return [[super alloc] initWithName:name andMSGDelegate:networkDelegate];
}

- (instancetype)initWithName:(NSString *)name andMSGDelegate:(id<MSGNetWorkProtocol>)networkDelegate
{
    NSArray* path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [path objectAtIndex:0];
    NSLog(@"documents : %@", docDir);
    _cusName = name;
    //_uuid = [NSString stringWithFormat:@"%@/test.db", docDir];
    NSString* dbName = [NSString stringWithFormat:@"%@/%@_msg.db", docDir, name];
    //sqlite3_open(dbName.UTF8String, &_DB);
    sqlite3* DB = [DBManager openDBWithName:dbName];
    self.cusName = name;
    self.networkDelegate = networkDelegate;
    self.visitedDatetimeDict = [[NSMutableDictionary alloc] init];
    self.msgManager = [[MessageManager alloc] initWithDBName:DB];
    self.fileManager = [[MsgFileManager alloc] initWithDB:DB];
    return self;
}

- (NSArray<MessageInfo*>*)getMessageWithStartIndex:(int)index andCount:(int)count
{
    return [_msgManager getMessageWithIndex:index andCount:count];
}

-(int) getMessageCount
{
    return [_msgManager getMessageCount];
}

-(BOOL) addMessageWithMessageInfo:(MessageInfo *)msgInfo
{
    return [_msgManager addMessage:msgInfo];
}

-(BOOL) deleteMessageWithMessageInfo:(MessageInfo *)msgInfo
{
//    NSDate *date = [TimeHelper getDatetimeFromString:msgInfo.getMsgDatetime];
//    NSDate *startDate = [date  dateByAddingTimeInterval:-intervalSec];
//    NSDate *endDate = [date  dateByAddingTimeInterval:intervalSec];
//    NSString* start = [TimeHelper getDateTimeStringFromDate:startDate];
//    NSString* end = [TimeHelper getDateTimeStringFromDate:endDate];
//    NSArray* fileArr = [_fileManager getFileInfoWithStartTime:start andEndTime:end];
//    for(int i = 0; i < fileArr.count; i++) {
//        [_fileManager deleteFileWithFileInfo:[fileArr objectAtIndex:i]];
//    }
    return [_msgManager deleteMessage:msgInfo];
}

-(BOOL) clearAllMessage
{

    NSArray* path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [path objectAtIndex:0];
    NSLog(@"documents : %@", docDir);
    NSString* dbName = [NSString stringWithFormat:@"%@/%@_msg.db", docDir, _cusName];
    [DBManager deleteDBWithName:dbName];
    return YES;
}

-(BOOL)compareWithSrcDatetime:(NSString *)srcDt andDstDatetime:(NSString *)dstDt
{
    NSDate *srcDt1 = [TimeHelper getDatetimeFromString:srcDt];
    NSDate *dstDt1 = [TimeHelper getDatetimeFromString:dstDt];
    NSTimeInterval interval = [srcDt1 timeIntervalSinceDate:dstDt1];
    if(interval <= 0) {
        return YES;
    }
    return NO;
    
}

-(BOOL)needQueryFromRemoteWithDatetime:(NSString *)datetime {
    NSString *dateTemplate = @"yyyy-MM-dd";
    NSString *key = [datetime substringToIndex:dateTemplate.length];
    BOOL bRet = YES;
    if([[self.visitedDatetimeDict allKeys] containsObject:key]) {
        bRet = ![self compareWithSrcDatetime:datetime andDstDatetime:[self.visitedDatetimeDict objectForKey:key]];
    }
   // NSLog(@"need query from remote : %@", bRet ? @"YES" : @"NO");
    return bRet;
    
}

-(NSArray <MsgFileInfo*>*)getFileListWithMessageInfo:(MessageInfo *)msgInfo
{

    NSDate *date = [TimeHelper getDatetimeFromString:msgInfo.getMsgDatetime];

    NSDate *start = [date dateByAddingTimeInterval:-intervalSec];
    NSDate *end = [date dateByAddingTimeInterval:intervalSec];
    NSString *startDate = [TimeHelper getDateTimeStringFromDate:start];
    NSString *endDate = [TimeHelper getDateTimeStringFromDate:end];
    
    NSArray* tmpArr = [_fileManager getFileInfoWithStartTime:startDate andEndTime:endDate];
    if([tmpArr count] != 0) {
        return tmpArr;
    }
    //判断当前请求的日期时间，在当天日期是否比数据库的当天日期时间大，大于则需要重新访问远端
    if([_fileManager checkDateInDatabaseWithDatetime:startDate]) {
        return tmpArr;
    }
    
    //判断这个日期时间是否已向远端请求过？
    if(![self needQueryFromRemoteWithDatetime:startDate]) {
        return tmpArr;
    }
    
    if(_networkDelegate == nil) {
        return tmpArr;
    }
    
    if([_networkDelegate respondsToSelector:@selector(loginWithInfo:)] == YES) {
        [ _networkDelegate loginWithInfo:_cusName];
    } else {
        return tmpArr;
    }
    
    if([_networkDelegate respondsToSelector:@selector(getFileWithStartDatetime:andEndDateTime:)] == YES) {
        tmpArr = [NSArray arrayWithArray: [_networkDelegate getFileWithStartDatetime:startDate andEndDateTime: endDate]];
        int i = 0;
        BOOL bRet = NO;
        for (i = 0; i < tmpArr.count; i++) {
            MsgFileInfo* info = [tmpArr objectAtIndex:i];
            bRet = [_fileManager addFileInfo:info];
            if(!bRet) {
                NSLog(@"add fileinfo to DB fail !!");
            }
            [info debug];
        }
        //re query
        
        tmpArr = [_fileManager getFileInfoWithStartTime:startDate andEndTime:endDate];
    }
    [self.visitedDatetimeDict setObject:endDate forKey:[endDate substringToIndex:@"yyyy-MM-dd".length]];
    return tmpArr;
}

-(NSData*) getThumbnailWithMsgFileInfo:(MsgFileInfo *)fileInfo
{
    NSData* data = [_fileManager getThumbnail:fileInfo];
    if(data.length > 0) {
        return data;
    }
    if([_networkDelegate respondsToSelector:@selector(loginWithInfo:)] == YES) {
        if (![_networkDelegate loginWithInfo:_cusName]) {
            return nil;
        }
    }
    if([_networkDelegate respondsToSelector:@selector(getThumbnailWithFileinfo:)] == YES) {
        data = [_networkDelegate getThumbnailWithFileinfo:fileInfo];
        if (data.length <= 0) {
            return nil;
        }
        [_fileManager addThumbnail:data andThumbnailSize:(int)data.length withConditon:fileInfo];
    }
    return data;
}

@end
