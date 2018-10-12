//
//  MessageCenter.h
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSGNetWorkProtocol.h"
#import "MessageInfo.h"
#import "MsgFileInfo.h"

@interface MessageCenter : NSObject
+ (instancetype)MessageCenterWithName:(NSString *)name andMsgDelegate:(id <MSGNetWorkProtocol>) networkDelegate;
- (instancetype)initWithName:(NSString*) name andMSGDelegate:(id <MSGNetWorkProtocol>) networkDelegate;

- (NSArray <MessageInfo*>*)getMessageWithStartIndex:(int) index andCount:(int)count;
- (int) getMessageCount;

- (NSArray <MsgFileInfo*>*)getFileListWithMessageInfo :(MessageInfo*) msgInfo;
- (NSData*)getThumbnailWithMsgFileInfo :(MsgFileInfo*) fileInfo;

- (BOOL)addMessageWithMessageInfo:(MessageInfo*) msgInfo;
- (BOOL)deleteMessageWithMessageInfo:(MessageInfo*) msgInfo;
- (BOOL)clearAllMessage;
@end
