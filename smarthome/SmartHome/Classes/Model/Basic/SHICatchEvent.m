//
//  SHICatchEvent.m
//  SmartHome
//
//  Created by ZJ on 2017/6/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHICatchEvent.h"

@implementation SHICatchEvent

+ (instancetype)iCatchEvent:(ICatchEvent *)icatchEvt {
    SHICatchEvent *evt = [self new];
    
    evt.eventID = icatchEvt->getEventID();
    evt.sessionID = icatchEvt->getSessionID();
    
    evt.intValue1 = icatchEvt->getIntValue1();
    evt.intValue2 = icatchEvt->getIntValue2();
    evt.intValue3 = icatchEvt->getIntValue3();
    
    evt.doubleValue1 = icatchEvt->getDoubleValue1();
    evt.doubleValue2 = icatchEvt->getDoubleValue2();
    evt.doubleValue3 = icatchEvt->getDoubleValue3();
	
	evt.stringValue1 = [NSString stringWithUTF8String:icatchEvt->getStringValue1().c_str()];
	evt.stringValue2 = [NSString stringWithUTF8String:icatchEvt->getStringValue2().c_str()];
	evt.stringValue3 = [NSString stringWithUTF8String:icatchEvt->getStringValue3().c_str()];
    
    if (icatchEvt->getFileValue()) {
        evt.fileValue = *(icatchEvt->getFileValue());
    }
    
    return evt;
}

@end
