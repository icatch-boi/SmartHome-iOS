// SHAccountSettingViewModel.m

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
 
 // Created by zj on 2019/4/15 3:43 PM.
    

#import "SHAccountSettingViewModel.h"
#import "SHAccountSettingItem.h"
#import "SHAccountSettingAvatarCell.h"
#import "SHAccountSettingCommonCell.h"
#import "SHAccountSettingSwitchCell.h"

@interface SHAccountSettingViewModel ()

@property (nonatomic, strong) NSArray<SHAccountSettingViewModelItem> *viewModelItems;

@end

@implementation SHAccountSettingViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self prepareData];
    }
    return self;
}

- (void)prepareData {
    id obj = [SHAccountSettingViewModel dataFromFile:@"AccountSettingItems"];
    
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)obj;
        NSString *rootKey = [dict.keyEnumerator nextObject];
        NSDictionary *itemsDict = dict[rootKey];
        
        NSMutableArray *viewModelItems = [NSMutableArray arrayWithCapacity:3];
        
        if ([itemsDict.allKeys containsObject:@"Basic"]) {
            NSArray *basicArray = itemsDict[@"Basic"];
            
            NSMutableArray *items = [NSMutableArray array];
            [basicArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHAccountSettingItem *item = [SHAccountSettingItem accountSettingItemWithDict:obj];
                if (item) {
                    [items addObject:item];
                }
            }];
            
            SHAccountSettingViewModelProfileItem *profileItem = [SHAccountSettingViewModelProfileItem baseItemWithAccountSettingItems:items];
            if (profileItem) {
                [viewModelItems addObject:profileItem];
            }
        }
        
        if ([itemsDict.allKeys containsObject:@"Service"]) {
            NSArray *basicArray = itemsDict[@"Service"];
            
            NSMutableArray *items = [NSMutableArray array];
            [basicArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHAccountSettingItem *item = [SHAccountSettingItem accountSettingItemWithDict:obj];
                if (item) {
                    [items addObject:item];
                }
            }];
            
            SHAccountSettingViewModelServiceItem *serviceItem = [SHAccountSettingViewModelServiceItem baseItemWithAccountSettingItems:items];
            if (serviceItem) {
                [viewModelItems addObject:serviceItem];
            }
        }
        
        if ([itemsDict.allKeys containsObject:@"Setting"]) {
            NSArray *basicArray = itemsDict[@"Setting"];
            
            NSMutableArray *items = [NSMutableArray array];
            [basicArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHAccountSettingItem *item = [SHAccountSettingItem accountSettingItemWithDict:obj];
                if (item) {
                    [items addObject:item];
                }
            }];
            
            SHAccountSettingViewModelSettingItem *settingItem = [SHAccountSettingViewModelSettingItem baseItemWithAccountSettingItems:items];
            if (settingItem) {
                [viewModelItems addObject:settingItem];
            }
        }
        
        self.viewModelItems = viewModelItems.copy;
    }
}

+ (id)dataFromFile:(NSString *)fileName {
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data == nil) {
        return data;
    }
    
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModelItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModelItems[section] rowCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <SHAccountSettingViewModelItem> item = self.viewModelItems[indexPath.section];
    
    UITableViewCell *cell = [item cellWithTableView:tableView forIndexPath:indexPath];
    
    return cell;
}

@end

#pragma mark - SHAccountSettingViewModelBaseItem
@implementation SHAccountSettingViewModelBaseItem

@synthesize items;
@synthesize rowCount;
@synthesize sectionTitle;
@synthesize rowHeight;
@synthesize type;

+ (instancetype)baseItemWithAccountSettingItems:(NSArray<SHAccountSettingItem *> *)items {
    id <SHAccountSettingViewModelItem> viewModelItem = [self new];
    
    viewModelItem.items = items;
    
    return viewModelItem;
}

- (NSInteger)rowCount {
    return self.items.count;
}

- (CGFloat)rowHeight {
    return 50.0;
}

- (UITableViewCell *)cellWithTableView:(UITableView *)tableView forIndexPath:(NSIndexPath *)indexPath {
    SHAccountSettingItem *item = items[indexPath.row];
    
    NSString *identifier = item.identifier;
    if ([identifier isEqualToString:NSStringFromClass([SHAccountSettingAvatarCell class])]) {
        SHAccountSettingAvatarCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        
        cell.item = item;
        
        return cell;
    } else if ([identifier isEqualToString:NSStringFromClass([SHAccountSettingCommonCell class])]) {
        SHAccountSettingCommonCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        
        cell.item = item;

        return cell;
    } else if ([identifier isEqualToString:NSStringFromClass([SHAccountSettingSwitchCell class])]) {
        SHAccountSettingSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        
        cell.item = item;

        return cell;
    }
    
    return [UITableViewCell new];
}

@end

#pragma mark - SHAccountSettingViewModelProfileItem
@implementation SHAccountSettingViewModelProfileItem

- (AccountSettingViewModelItemType)type {
    return AccountSettingViewModelItemTypeProfile;
}

- (CGFloat)rowHeight {
    return 100.0;
}

@end

#pragma mark - SHAccountSettingViewModelServiceItem
@implementation SHAccountSettingViewModelServiceItem

- (AccountSettingViewModelItemType)type {
    return AccountSettingViewModelItemTypeService;
}

@end

#pragma mark - SHAccountSettingViewModelSettingItem
@implementation SHAccountSettingViewModelSettingItem

- (AccountSettingViewModelItemType)type {
    return AccountSettingViewModelItemTypeSetting;
}

@end
