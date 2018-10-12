//
//  MSGNetWorkProtocol.h
//  Sqlite3Test
//
//  Created by sa on 20/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MsgFileInfo.h"
@protocol MSGNetWorkProtocol <NSObject>
-(BOOL) loginWithInfo:(NSString*) info;
-(NSArray<MsgFileInfo*>*) getFileWithStartDatetime:(NSString*) dateTime andEndDateTime: (NSString*) endDateTime;
-(NSData*) getThumbnailWithFileinfo:(MsgFileInfo*) info;
@end
