//
//  MsgFileManager.h
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MsgFileInfo.h"
#import <sqlite3.h>
static NSString * const kFileTableName = @"MsgFileTable";
@interface MsgFileManager : NSObject
-(instancetype) initWithDB:(sqlite3*) DB;

-(BOOL) addFileInfo:(MsgFileInfo*) info;
-(BOOL) addFileInfos:(NSArray *)infos;
-(BOOL) addThumbnail:(NSData*) thumbnail andThumbnailSize :(int) size withConditon:(MsgFileInfo*) info;
-(BOOL) checkDateInDatabaseWithDatetime:(NSString *)datetime;
-(NSArray*) getFileInfoWithStartTime:(NSString*)start andEndTime:(NSString*) end;
-(NSData*) getThumbnail:(MsgFileInfo*) info;
-(BOOL) clearAllFile;
-(BOOL) deleteFileWithFileInfo:(MsgFileInfo*) info;

@end
