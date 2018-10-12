//
//  ZJGridViewController.h
//  ZJPhotoBrowserTest
//
//  Created by ZJ on 2018/5/29.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZJPhotoBrowserController.h"

@interface ZJGridViewController : UICollectionViewController

@property (nonatomic, weak) ZJPhotoBrowserController *browser;
@property (nonatomic, assign) CGPoint initialContentOffset;

- (instancetype)initWithFrame:(CGRect)frame;
//- (void)adjustOffsetsAsRequired;

@end
