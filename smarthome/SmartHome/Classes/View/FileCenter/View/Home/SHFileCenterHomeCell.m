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
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 让控制器的view 的大小和cell的大小一样
    self.filesController.view.frame = self.bounds;
}

- (void)setDateString:(NSString *)dateString {
    self.filesController.dateString = dateString;
}

@end
