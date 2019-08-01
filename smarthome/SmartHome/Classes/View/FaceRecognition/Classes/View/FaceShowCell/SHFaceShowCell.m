// SHFaceShowCell.m

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
 
 // Created by zj on 2019/8/1 2:42 PM.
    

#import "SHFaceShowCell.h"
#import "FRDFaceInfo.h"
#import "UIImageView+WebCache.h"

static const CGFloat kMagin = 2;

@implementation SHFaceShowCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFaceInfo:(FRDFaceInfo *)faceInfo {
    _faceInfo = faceInfo;
    
    self.textLabel.text = faceInfo.name;
    
    UIImage *icon = faceInfo.faceImage;
    CGFloat iconH = CGRectGetHeight(self.frame) - 2 * kMagin;
    CGSize iconSize = CGSizeMake(iconH, iconH);
    
    if (icon != nil) {
        self.imageView.image = [icon ic_cornerImageWithSize:iconSize backColor:self.backgroundColor radius:iconH * 0.5];
    } else {
        NSURL *url = [[NSURL alloc] initWithString:faceInfo.url];

        [self.imageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"portrait"] options:SDWebImageRefreshCached completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {

            if (image != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = [image ic_cornerImageWithSize:iconSize backColor:self.backgroundColor radius:iconH * 0.5];
                    faceInfo.faceImage = image;
                });
            }
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(CGRectGetMinX(self.imageView.frame) + kMagin, CGRectGetMinY(self.imageView.frame) + kMagin, CGRectGetWidth(self.imageView.frame) - 2 * kMagin, CGRectGetHeight(self.imageView.frame) - 2 * kMagin);
}

@end
