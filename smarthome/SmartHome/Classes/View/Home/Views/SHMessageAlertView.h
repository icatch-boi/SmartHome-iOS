//
//  SHMessageAlertView.h
//  SmartHome
//
//  Created by ZJ on 2017/6/7.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kBounds [UIScreen screenBounds]
#define kHeight kBounds.size.height
#define kWidth  kBounds.size.width
#define kAlertViewWidth 44

//typedef enum : NSUInteger {
//    PushMessageTypePir = 100,
//    PushMessageTypeLowPower = 102,
//    PushMessageTypeSDCardFull = 103,
//    PushMessageTypeSDCardError = 104,
//    PushMessageTypeTamperAlarm = 105,
//    PushMessageTypeRing = 201,
//    PushMessageTypeFDHit = 202,
//    PushMessageTypeFDMiss = 203,
//    PushMessageTypePushTest = 204,
//} PushMessageType;

@class SHMessage;
@interface SHMessageAlertView : UIView

+ (instancetype)messageAlertViewWithController:(UIViewController *)vc message:(SHMessage *)msg cameras:(NSArray *)cameras;

@end
