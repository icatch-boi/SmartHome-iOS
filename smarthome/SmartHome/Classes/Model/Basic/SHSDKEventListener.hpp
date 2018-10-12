//
//  SHSDKEventListener.hpp
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#ifndef SHSDKEventListener_hpp
#define SHSDKEventListener_hpp

#include <stdio.h>
#import "SHICatchEvent.h"

class SHSDKEventListener: public Listener {
private:
    id object;
    SEL callback;
    void eventNotify(ICatchEvent *icatchEvt);
public:
    SHSDKEventListener(id object, SEL callback);
};

#endif /* SHSDKEventListener_hpp */
