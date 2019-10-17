//
//  SHFilesCell.m
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "SHFilesCell.h"

@interface SHFilesCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *recodTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *recodTypeLabel;

@end

@implementation SHFilesCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setDateString:(NSString *)dateString {
    self.deviceNameLabel.text = dateString;
}

@end
