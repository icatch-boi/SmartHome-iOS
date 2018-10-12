//
//  ZJGridCell.h
//  ZJPhotoBrowserTest
//
//  Created by ZJ on 2018/5/29.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZJPhoto.h"

@interface ZJGridCell : UICollectionViewCell

@property (nonatomic, strong) id <ZJPhotoProtocol> photo;
@property (nonatomic, assign) BOOL selectionMode;
@property (nonatomic, assign) BOOL isSelected;

- (void)displayImage;

@end
