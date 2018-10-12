//
//  SHVideoFormatTransformer.m
//  SmartHome
//
//  Created by ZJ on 2017/12/25.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHVideoFormatTransformer.h"
#import "SHVideoFormat.h"

@implementation SHVideoFormatTransformer

+ (Class)transformedValueClass
{
    return [SHVideoFormat class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end
