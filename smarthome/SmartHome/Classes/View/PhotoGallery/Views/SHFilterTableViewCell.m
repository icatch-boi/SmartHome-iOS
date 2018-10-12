//
//  SHFilterTableViewCell.m
//  SmartHome
//
//  Created by ZJ on 2017/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHFilterTableViewCell.h"

@interface SHFilterTableViewCell ()

@end

@implementation SHFilterTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSelectedStatus:(BOOL)selected {
    self.tag = selected;
    self.imageView.image = selected ? self.selectedImage : self.unSelectedImage;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withSelectedImage:(UIImage *)selectedImage withUnSelectedImage:(UIImage *)unSelectedImage {
   SHFilterTableViewCell *instance = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (!selectedImage) {
        self.selectedImage = [UIImage imageNamed:@"ic_done_red_24dp"];
    } else {
        self.selectedImage = selectedImage;
    }
    
    if (!unSelectedImage) {
        self.unSelectedImage = [UIImage imageNamed:@"ic_done_gray_24dp"];
    } else {
        self.unSelectedImage = unSelectedImage;
    }
    
   return instance;
}

- (void)setItem:(NSDictionary *)item {
    _item = item;
    
    NSString *identifier = item[@"Identifier"];
    self.textLabel.text = [[identifier componentsSeparatedByString:@":"] lastObject];
    
    BOOL isSelected = [[NSUserDefaults standardUserDefaults] boolForKey:identifier];
    if (isSelected) {
        [self setSelectedStatus:YES];
    } else {
        [self setSelectedStatus:NO];
    }
}

@end
