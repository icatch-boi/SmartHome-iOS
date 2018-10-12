//
//  SHThumbFile.m
//  SmartHome
//
//  Created by ZJ on 2017/5/24.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHFileThumbnail.h"

@implementation SHFileThumbnail

+ (instancetype)fileThumbnailWithFile:(ICatchFile *)file andThumbnailData:(NSData *)data {
    SHFileThumbnail *ft = [[self alloc] init];
    
    ft.fileHandle = file->getFileHandle();
    ft.fileType = file->getFileType();
    ft.fileName = [NSString stringWithFormat:@"%s", file->getFileName().c_str()];
    ft.createDate = [NSString stringWithFormat:@"%s", file->getFileDate().c_str()];
    ft.createTime = [NSString stringWithFormat:@"%s", file->getFileTime().c_str()];
    ft.motion = file->getFileMotion();
    ft.duration = file->getFileDuration();
    ft.thumbnailSize = file->getFileThumbSize();
    ft.thumbnail = data;
    
    return ft;
}

@end
