// SHAccountSettingViewModelItem.h

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
 
 // Created by zj on 2019/4/16 4:55 PM.
    

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kCommonRowHeight = 50.0;
static const CGFloat kProfileRowHeight = 100.0;

@class SHAccountSettingItem;
@protocol SHAccountSettingViewModelItem <NSObject>

@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, copy) NSString *sectionTitle;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, strong) NSArray<SHAccountSettingItem *> *items;

- (UITableViewCell *)cellWithTableView:(UITableView *)tableView forIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark - SHAccountSettingViewModelBaseItem
@interface SHAccountSettingViewModelBaseItem : NSObject <SHAccountSettingViewModelItem>

+ (instancetype)baseItemWithAccountSettingItems:(NSArray<SHAccountSettingItem *>*)items;

@end

#pragma mark - SHAccountSettingViewModelProfileItem
@interface SHAccountSettingViewModelProfileItem : SHAccountSettingViewModelBaseItem

@end

#pragma mark - SHAccountSettingViewModelServiceItem
@interface SHAccountSettingViewModelServiceItem : SHAccountSettingViewModelBaseItem

@end

#pragma mark - SHAccountSettingViewModelSettingItem
@interface SHAccountSettingViewModelSettingItem : SHAccountSettingViewModelBaseItem

- (void)modifyAccountPasswordHandle;

@end

NS_ASSUME_NONNULL_END
