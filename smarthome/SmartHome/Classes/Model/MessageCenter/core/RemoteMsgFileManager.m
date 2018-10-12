// RemoteMsgFileManager.m

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
 
 // Created by sa on 2018/5/30 上午10:43.
    

#import "RemoteMsgFileManager.h"
#import <unistd.h>
#import <Dispatch/Dispatch.h>
#import <UIKit/UIkit.h>
#import <CoreData/CoreData.h>
typedef NS_ENUM(NSInteger, QueryState) {
    QueryStateTodo = 0,
    QueryStateDoing ,
    QueryStateDone ,
    QueryStateError,
};
@interface RemoteMsgFileManager()
@property (nonatomic, strong) id delegate;
@property NSMutableDictionary *taskDict;
@property (nonatomic, strong) MsgFileManager *fileManager;
@property (nonatomic) dispatch_queue_t threadQueue;
@property BOOL running;
@end

@implementation RemoteMsgFileManager
+(instancetype)remoteMsgFileManagerWithMsgFileManager:(MsgFileManager *)fileManager andNetWorkProtocol:(id)delegate
{
    return [[super alloc] initRemoteMsgFileManagerWithMsgFileManager:fileManager andNetWorkProtocol:delegate];
}

-(instancetype)initRemoteMsgFileManagerWithMsgFileManager:(MsgFileManager *)fileManager andNetWorkProtocol:(id)delegate
{
    self = [super init];
    if(self) {
        self.delegate = delegate;
        self.taskDict = [[NSMutableDictionary alloc] init];
        self.running = NO;
        
    }
    return self;
}
-(void)changeValueForKey:(NSString *)key withValue:(QueryState)state
{
    [self.taskDict setObject:[NSNumber numberWithInteger:state] forKey:key];
}

- (NSString*)getATask
{
    NSString *date = nil;
    for(NSString *key in self.taskDict) {
        NSInteger  state = [[self.taskDict objectForKey:key] integerValue] ;
        if(state != QueryStateDone || state != QueryStateError) {
            date = key;
            break;
        }
    }
    return date;
}

- (BOOL)queryFilesWithDate:(NSString *)date
{
    if([[self.taskDict allKeys] containsObject:date]) {
        return YES;
    }
    [self.taskDict setObject:[NSNumber numberWithInteger:QueryStateTodo] forKey:date];
    return YES;
}

- (void)runQuery
{
    //self.threadQueue = dispatch_queue_create(@"XJ.MSGCenter.File.Queue", 0);
    
    self.running = YES;
    dispatch_async(self.threadQueue, ^{
        while (self.running) {
            NSString *startDate = [self getATask];
            if(startDate == nil) {
                usleep(500);
                continue;
            }
            
            NSString *endDate = startDate;
            if([self.delegate respondsToSelector:@selector(getFileInfoWithStartTime:andEndTime:)]) {
                NSArray * fileInfos = [self.delegate getFileInfoWithStartTime:startDate andEndTime:endDate];
                [self changeValueForKey:startDate withValue:QueryStateDone];
              
                if(fileInfos.count) {
                    [self.fileManager addFileInfos:fileInfos];
                }
            } else {
                usleep(500);
            }
        };
    });
    
}
@end
