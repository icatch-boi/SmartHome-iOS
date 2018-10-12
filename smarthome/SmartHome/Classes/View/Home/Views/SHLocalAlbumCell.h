//
//  SHLocalAlbumCell.h
//  SmartHome
//
//  Created by ZJ on 2017/7/27.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class SHLocalAlbumCell;
@protocol SHLocalAlbumCellDelegate <NSObject>

- (void)localAlbumCell:(SHLocalAlbumCell *)cell showLocalMediaBrowser:(UINavigationController *)nav;
- (void)localAlbumCell:(SHLocalAlbumCell *)cell deleteLocalAssetWithIndex:(NSUInteger)index tag:(NSInteger)tag completionHandler:(nullable void(^)(BOOL success))completionHandler;

@end

@interface SHLocalAlbumCell : UITableViewCell

@property (nonatomic, strong) NSArray *assetsArray;
@property (nonatomic, copy) void (^showLocalMediaBrowserBlock)(UINavigationController *nc);
@property (nonatomic, copy) BOOL (^deleteLocalFileBlock)(NSInteger tag, NSInteger index);
@property (nonatomic) int mediaType;

@property (nonatomic, weak) id <SHLocalAlbumCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
