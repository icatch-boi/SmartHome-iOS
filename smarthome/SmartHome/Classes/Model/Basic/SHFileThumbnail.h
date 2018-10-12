//
//  SHThumbFile.h
//  SmartHome
//
//  Created by ZJ on 2017/5/24.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHFileThumbnail : NSObject

@property (nonatomic, assign) NSInteger fileHandle;
@property (nonatomic, assign) NSInteger fileType;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *createDate;
@property (nonatomic, copy) NSString *createTime;
@property (nonatomic, assign) NSInteger motion;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger thumbnailSize;
@property (nonatomic, strong) NSData *thumbnail;

+ (instancetype)fileThumbnailWithFile:(ICatchFile *)file andThumbnailData:(NSData *)data;

@end
