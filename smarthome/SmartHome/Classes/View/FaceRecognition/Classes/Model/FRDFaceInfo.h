//
//  FRDFaceInfo.h
//  FaceRecognition
//
//  Created by ZJ on 2018/9/13.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FRDFaceInfo : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *url;

- (instancetype)initWithDict:(NSDictionary *)dict;
+ (instancetype)faceInfoWithDict:(NSDictionary *)dict;

@end
