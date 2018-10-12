//
//  MessageInfo.h
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageInfo : NSObject
-(instancetype) initWithMsgID:(int) msgID andDevID : (NSString*) devID andDatetime : (NSString*) datetime andMsgType : (int) msgType ;
-(instancetype) initWithIndex:(int) index andMsgID:(int) msgID andDevID : (NSString*) devID andDatetime : (NSString*) datetime andMsgType : (int) msgType;
-(int) getMsgID;
-(int) getMsgIndex;
-(int) getMsgType;
-(NSString*) getMsgDatetime;
-(NSString*) getDevID;
-(void) debug;
@end
