//
//  MsgFileInfo.m
//  Sqlite3Test
//
//  Created by sa on 19/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//

#import "MsgFileInfo.h"

@implementation MsgFileInfo
-(void)debug
{
    NSLog(@"name : %@ , handle : %zd, datetime : %@, duration : %zd, thumbnailsize : %zd", _name, _handle, _datetime, _duration, _thumnailSize);
}
@end
