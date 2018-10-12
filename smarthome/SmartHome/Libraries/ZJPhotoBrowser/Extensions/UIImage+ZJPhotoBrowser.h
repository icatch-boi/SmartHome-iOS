//
//  UIImage+ZJPhotoBrowser.h
//  ZJPhotoBrowserTest
//
//  Created by ZJ on 2018/6/1.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ZJPhotoBrowser)

+ (UIImage *)imageForResourcePath:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle;

@end
