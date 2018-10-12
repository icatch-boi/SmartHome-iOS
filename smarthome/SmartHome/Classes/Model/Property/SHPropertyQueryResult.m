//
//  SHPropertyQueryResult.m
//  SmartHome
//
//  Created by yh.zhang on 17/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHPropertyQueryResult.h"

@interface SHPropertyQueryResult ()

@property (nonatomic) list<ICatchTransProperty> propertyList;

@end

@implementation SHPropertyQueryResult

+ (instancetype)propertyQueryResultWithTransProperty:(list<ICatchTransProperty>)propertyList {
    SHPropertyQueryResult *result = [[SHPropertyQueryResult alloc] init];
    result.propertyList = propertyList;
    
    return result;
}

- (int)praseInt:(int)propertId{
    for(ICatchTransProperty temp:_propertyList) {
        if(temp.getPropertyID() == propertId){
            return temp.getStatus() ? temp.getPropertyInt() : SHInvalidProperty;
        }
    }
    return SHInvalidProperty;
}

- (NSString *)praseString:(int)propertId{
    for(ICatchTransProperty temp:_propertyList){
        if(temp.getPropertyID() == propertId){
            SHLogDebug(SHLogTagAPP, @"------> %s", temp.getPropertyString().c_str());
            return [NSString stringWithFormat:@"%s",temp.getPropertyString().c_str()];
        }
    }
    
    return nil;
}

- (string)praseString2:(int)propertId{
    for(ICatchTransProperty temp:_propertyList){
        if(temp.getPropertyID() == propertId){
            SHLogDebug(SHLogTagAPP, @"------> %s", temp.getPropertyString().c_str());
            return temp.getPropertyString();
        }
    }
    
    return nil;
}

- (SHRangeItem *)praseRangeItem:(int)propertId{
    for(ICatchTransProperty temp:_propertyList){
        if(temp.getPropertyID() == propertId){
            return [SHRangeItem rangeItemWithData:temp.getRangeMin() max:temp.getRangeMax() step:temp.getRangeStep()];
        }
    }
    
    return nil;
}

- (list<NSString*> *)praseRangeListString:(int)propertId{
    for(ICatchTransProperty temp:_propertyList) {
        if(temp.getPropertyID() == propertId){
            list<string> *supportedListString = new list<string>();
            temp.getSupportedList(*supportedListString);
            if(supportedListString == nil){
                return nil;
            }
            
            list<NSString *> *supportedListString1 = new list<NSString *>();
            for(string value:*supportedListString){
                supportedListString1->push_back([NSString stringWithFormat:@"%s",value.c_str()]);
            }
            
            return supportedListString1;
        }
    }
    
    return nil;
}

- (list<int> *)praseRangeListInt:(int)propertId{
    for(ICatchTransProperty temp:_propertyList) {
        if(temp.getPropertyID() == propertId){
            list<int> *supportedListInt = new list<int>();
            temp.getSupportedList(*supportedListInt);
            return supportedListInt;
        }
    }
    
    return nil;
}

@end
