//
//  MessageInfo.m
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import "MessageInfo.h"
@interface MessageInfo()
@property int msgID;
@property int msgType;
@property int msgIndex;
@property NSString* datetime;
@property NSString* devID;
@end

@implementation MessageInfo
-(instancetype) initWithMsgID:(int)msgID andDevID:(NSString *)devID andDatetime:(NSString *)datetime andMsgType:(int)msgType
{
    self = [super init];
    self.msgID = msgID;
    self.datetime = datetime;
    self.devID = devID;
    self.msgType = msgType;
    return self;
}

-(instancetype) initWithIndex:(int)index andMsgID:(int)msgID andDevID:(NSString *)devID andDatetime:(NSString *)datetime andMsgType:(int)msgType
{
    self = [super init];
    self.msgIndex = index;
    self.msgID = msgID;
    self.datetime = datetime;
    self.devID = devID;
    self.msgType = msgType;
    return self;
}

-(int)getMsgType {
    return _msgType;
}

-(int) getMsgIndex
{
    return _msgIndex;
}

-(int) getMsgID{
    return _msgID;
}

-(NSString*) getMsgDatetime {
    return _datetime;
}

-(NSString*) getDevID {
    return _devID;
}

-(void) debug
{
    NSLog(@"MsgIndex : %d MsgID : %d DevID : %@ : DateTime : %@ : type : %d",_msgIndex , _msgID, _devID, _datetime, _msgType);
}
@end
