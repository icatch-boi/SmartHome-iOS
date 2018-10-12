//
//  SHSDKEventListener.cpp
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#include "SHSDKEventListener.hpp"

SHSDKEventListener::SHSDKEventListener(id object, SEL callback) {
    this->object = object;
    this->callback = callback;
}

void SHSDKEventListener::eventNotify(ICatchEvent *icatchEvt) {
    NSString *callbackName = NSStringFromSelector(callback);
    
    if (icatchEvt && [callbackName containsString:@":"]) {
        SHICatchEvent *evt = [SHICatchEvent iCatchEvent:icatchEvt];
        
        [object performSelectorInBackground:callback withObject:evt];
    } else {
        [object performSelectorInBackground:callback withObject:nil];
    }
}
