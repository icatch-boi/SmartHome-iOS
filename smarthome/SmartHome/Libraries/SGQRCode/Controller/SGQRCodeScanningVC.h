//
//  SGQRCodeScanningVC.h
//  SGQRCodeExample
//
//  Created by apple on 17/3/20.
//  Copyright © 2017年 Sorgle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGQRCodeScanningVC : UIViewController

- (void)setGestureHandle:(void (^)(UIView *sender))gestureHandle;
@end
