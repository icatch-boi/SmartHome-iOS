//
//  SHFilterTableViewCell.h
//  SmartHome
//
//  Created by ZJ on 2017/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHFilterTableViewCell : UITableViewCell

@property (nonatomic) UIImage *selectedImage;
@property (nonatomic) UIImage *unSelectedImage;
@property (nonatomic) NSDictionary *item;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withSelectedImage:(UIImage *)selectedImage withUnSelectedImage:(UIImage *)unSelectedImage;
- (void)setSelectedStatus:(BOOL)selected;

@end
