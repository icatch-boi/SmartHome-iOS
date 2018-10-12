//
//  SHFile.m
//  SmartHome
//
//  Created by ZJ on 2017/6/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHFile.h"

@implementation SHFile

+ (instancetype)fileWithUid:(NSString *)uid file:(ICatchFile)f{
	SHFile *file = [self new];
	file.uid = uid;
	file.f = f;
	
	return file;
}

@end
