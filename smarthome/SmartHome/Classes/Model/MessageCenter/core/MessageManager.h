//
//  MessageManager.h
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MessageInfo.h"
#import <sqlite3.h>

static NSString * const kMsgTableName = @"MessageTable";
@interface MessageManager : NSObject

- (instancetype)initWithDBName:(sqlite3*)DB;
- (NSArray <MessageInfo*> *)getMessageWithIndex:(int) index andCount : (int) count;
- (BOOL)addMessage:(MessageInfo*) info;
- (BOOL)deleteMessage : (MessageInfo*) info;
- (BOOL)clearAllMessage ;
- (int)getMessageCount;
@end
