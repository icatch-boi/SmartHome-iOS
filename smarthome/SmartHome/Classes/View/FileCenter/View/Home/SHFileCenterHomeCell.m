//
//  SHFileCenterHomeCell.m
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "SHFileCenterHomeCell.h"
#import "SHFilesController.h"

@interface SHFileCenterHomeCell ()

@property (nonatomic, strong) SHFilesController *filesController;

@end

@implementation SHFileCenterHomeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Files" bundle:nil];
    self.filesController = [sb instantiateInitialViewController];
    
    [self.contentView addSubview:self.filesController.view];
    WEAK_SELF(self);
    [self.filesController setDidSelectBlock:^(SHS3FileInfo * _Nonnull fileInfo) {
        if ([weakself.delegate respondsToSelector:@selector(fileCenterHomeCell:didSelectWithFileInfo:)]) {
            [weakself.delegate fileCenterHomeCell:weakself didSelectWithFileInfo:fileInfo];
        }
    }];
    [self.filesController setEditStateBlock:^{
        if ([weakself.delegate respondsToSelector:@selector(enterEditeStateWithCell:)]) {
            [weakself.delegate enterEditeStateWithCell:weakself];
        }
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 让控制器的view 的大小和cell的大小一样
    self.filesController.view.frame = self.bounds;
}

- (void)setDateFileInfo:(SHDateFileInfo *)dateFileInfo {
    _dateFileInfo = dateFileInfo;
    
    self.filesController.dateFileInfo = dateFileInfo;
}

- (void)cancelEditAction {
    [self.filesController cancelEditAction];
}

@end
