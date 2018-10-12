//
//  SHRangeItem.h
//  SmartHome
//
//  Created by yh.zhang on 17/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHRangeItem : NSObject

@property (nonatomic) NSInteger min;
@property (nonatomic) NSInteger max;
@property (nonatomic) NSInteger step;

+ (instancetype)rangeItemWithData:(NSInteger)min max:(NSInteger)max step:(NSInteger)step;

@end
