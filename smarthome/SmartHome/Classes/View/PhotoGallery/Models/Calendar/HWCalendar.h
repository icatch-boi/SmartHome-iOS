//
//  HWCalendar.h
//  HWCalendar
//
//  Created by wqb on 2017/1/12.
//  Copyright © 2017年 hero_wqb. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HWCalendar;

@protocol HWCalendarDelegate <NSObject>

- (void)calendar:(HWCalendar *)calendar didClickSureButtonWithDate:(NSString *)date;
- (void)calendarWithGetDataFailedHandler:(HWCalendar *)calendar;

@end

@interface HWCalendar : UIView

@property (nonatomic, assign) BOOL showTimePicker; //default is NO. doesn't show timePicker

@property (nonatomic, weak) id<HWCalendarDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame andCurDateTime:(NSDate *)date cameraObj:(SHCameraObject *)shCamObj;
- (void)show;
- (void)dismiss;

@end
