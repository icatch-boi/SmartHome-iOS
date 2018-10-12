//
//  MsgFileInfo.h
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MsgFileInfo : NSObject
@property (nonatomic, copy) NSString* datetime;
@property (nonatomic, assign) NSInteger handle;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger thumnailSize;
-(void) debug;
@end
