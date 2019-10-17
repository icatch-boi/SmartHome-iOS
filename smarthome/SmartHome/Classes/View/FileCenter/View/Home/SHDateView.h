//
//  SHDateView.h
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SHDateView;
@protocol SHDateViewDelete <NSObject>

- (void)clickedActionWithDateView:(SHDateView *)dateView;

@end

@interface SHDateView : UIView

@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, weak) id<SHDateViewDelete> delegate;

+ (instancetype)dateViewWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
