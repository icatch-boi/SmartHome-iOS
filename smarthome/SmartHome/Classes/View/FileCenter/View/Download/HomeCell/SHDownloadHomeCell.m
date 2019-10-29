// SHDownloadHomeCell.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2019/10/25 3:10 PM.
    

#import "SHDownloadHomeCell.h"
#import "SHDownloadController.h"

@interface SHDownloadHomeCell ()

@property (nonatomic, strong) SHDownloadController *downloadController;

@end

@implementation SHDownloadHomeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Download" bundle:nil];
    self.downloadController = [sb instantiateViewControllerWithIdentifier:NSStringFromClass(SHDownloadController.class)];
    
    [self.contentView addSubview:self.downloadController.view];
    
    WEAK_SELF(self);
    [self.downloadController setEnterLocalAlbumBlock:^{
        if ([weakself.delegate respondsToSelector:@selector(enterLocalAlbumWithCell:)]) {
            [weakself.delegate enterLocalAlbumWithCell:weakself];
        }
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 让控制器的view 的大小和cell的大小一样
    self.downloadController.view.frame = self.bounds;
}

- (void)setOptionItem:(SHOptionItem *)optionItem {
    _optionItem = optionItem;
    
    self.downloadController.optionItem = optionItem;
}

- (void)setDeviceID:(NSString *)deviceID {
    _deviceID = deviceID;
    
    self.downloadController.deviceID = deviceID;
}

@end
