//
//  NSArray+Map1.h
//  XYChart
//
//  Created by Daniel on 2018/7/21.
//  Copyright © 2018 uyiuyao. All rights reserved.
//

#import "NSArray+XYChart.h"

@implementation NSArray (XYChart)

- (NSArray *)xy_map:(nonnull id (^)(id obj, NSUInteger idx))block
{
    NSAssert(block!=nil, @"block 不能为空, 但还是做了保护");
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id  _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
        id value = block ? block(object, index) : [NSNull null];
        [result addObject:value];
    }];
    
    return [NSArray arrayWithArray:result];
}

- (id)xy_max:(NSComparisonResult (^)(id, id))block
{
    NSAssert(block!=nil, @"block 不能为空, 但还是做了保护");

    if (self.count==0) { return nil; }
    if (self.count==1) { return self.firstObject;}
    id max = self.firstObject;
    for (int i=1; i<self.count; i++) {
        if (block(max, self.xy_safeIdx(i)) == NSOrderedAscending) {
            max = self.xy_safeIdx(i);
        }
    }
    return max;
}

- (id)xy_min:(NSComparisonResult (^)(id, id))block
{
    NSAssert(block!=nil, @"block 不能为空, 但还是做了保护");

    if (self.count==0) { return nil; }
    if (self.count==1) { return self.firstObject;}
    id min = self.firstObject;
    for (int i=1; i<self.count; i++) {
        if (block(min, self.xy_safeIdx(i)) == NSOrderedDescending) {
            min = self.xy_safeIdx(i);
        }
    }
    return min;
}

- (id  _Nonnull (^)(NSUInteger))xy_safeIdx
{
    __weak typeof(self) weakSelf = self;
    id (^block)(NSUInteger index) = ^(NSUInteger index) {
        return (weakSelf.count-1)<index ? nil : weakSelf[index];
    };
    return block;
}

- (NSArray * (^)(id (^)(id, NSUInteger)))xy_mapIndex
{
    __weak typeof(self) weakSelf = self;
    NSArray * (^returnBlock)(id (^)(id, NSUInteger)) = ^(id (^itemConfigBlock)(id, NSUInteger)) {
        NSMutableArray *returnArray = @[].mutableCopy;
        for (NSUInteger idx=0; idx<weakSelf.count; idx++) {
            id originItem = self[idx];
            id configItem = nil;
            if (itemConfigBlock) {
                configItem = itemConfigBlock(originItem, idx);
            }
            returnArray.xy_safeAdd(configItem);
        }
        return [NSArray arrayWithArray:returnArray];
    };
    return returnBlock;
}

- (NSArray * (^)(id (^)(id)))xy_map
{
    __weak typeof(self) weakSelf = self;
    NSArray * (^returnBlock)(id (^)(id)) = ^(id (^itemConfigBlock)(id)) {
        NSMutableArray *returnArray = @[].mutableCopy;
        for (NSUInteger idx=0; idx<weakSelf.count; idx++) {
            id originItem = self[idx];
            id configItem = nil;
            if (itemConfigBlock) {
                configItem = itemConfigBlock(originItem);
            }
            returnArray.xy_safeAdd(configItem);
        }
        return [NSArray arrayWithArray:returnArray];
    };
    return returnBlock;
}

@end


@implementation NSMutableArray (XYChart)

- (void (^)(id _Nonnull))xy_safeAdd
{
    __weak typeof(self) weakSelf = self;
    void (^block)(id obj) = ^(id obj) {
        if (obj) {
            [weakSelf addObject:obj];
        }
    };
    return block;
}

@end
