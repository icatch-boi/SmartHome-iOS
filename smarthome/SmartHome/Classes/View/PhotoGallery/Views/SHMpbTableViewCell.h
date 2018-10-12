//
//  SHMpbTableViewCell.h
//  SmartHome
//
//  Created by ZJ on 2017/5/4.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHMpbTableViewCell : UITableViewCell

@property (nonatomic) ICatchFile *file;

@property (weak, nonatomic) IBOutlet UIImageView *fileThumbs;
@property (weak, nonatomic) IBOutlet UILabel *cameraNameLabel;

- (void)setSelectedConfirmIconHidden:(BOOL)value;

@end
