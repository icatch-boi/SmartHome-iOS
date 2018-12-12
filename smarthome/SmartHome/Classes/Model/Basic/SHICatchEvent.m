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

- (NSString *)description {
    NSDictionary *dict = @{@"eventID": [NSString stringWithFormat:@"0x%x", self.eventID],
                           @"sessionID": [NSString stringWithFormat:@"%d", self.sessionID],
                           @"intValue1": [NSString stringWithFormat:@"%d", self.intValue1],
                           @"intValue2": [NSString stringWithFormat:@"%d", self.intValue2],
                           @"intValue3": [NSString stringWithFormat:@"%d", self.intValue3],
                           @"doubleValue1": [NSString stringWithFormat:@"%f", self.doubleValue1],
                           @"doubleValue2": [NSString stringWithFormat:@"%f", self.doubleValue2],
                           @"doubleValue3": [NSString stringWithFormat:@"%f", self.doubleValue3],
                           @"stringValue1": self.stringValue1,
                           @"stringValue2": self.stringValue2,
                           @"stringValue3": self.stringValue3,
                           };
    
    return [NSString stringWithFormat:@"<%@: %p, %@>", self.class, self, dict.description];
}

@end
