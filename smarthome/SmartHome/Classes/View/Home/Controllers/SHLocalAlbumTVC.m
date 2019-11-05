//
//  SHLocalAlbumTVC.m
//  SmartHome
//
//  Created by ZJ on 2017/7/27.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHLocalAlbumTVC.h"
#import "SHLocalAlbumCell.h"
#import <Photos/Photos.h>
#import "XJLocalAssetHelper.h"

@interface SHLocalAlbumTVC () <SHLocalAlbumCellDelegate>

@property(nonatomic, strong) NSMutableDictionary *localAssetsDict;
@property (nonatomic, strong) NSMutableArray *localAssetInfoMArray;


@end

@implementation SHLocalAlbumTVC

- (NSMutableDictionary *)localAssetsDict {
    if (_localAssetsDict == nil) {
        _localAssetsDict = [[NSMutableDictionary alloc] initWithCapacity:[SHCameraManager sharedCameraManger].smarthomeCams.count];
    }
    
    return _localAssetsDict;
}

- (NSMutableArray *)localAssetInfoMArray {
    if (_localAssetInfoMArray == nil) {
        _localAssetInfoMArray = [NSMutableArray arrayWithArray:[XJLocalAssetHelper sharedLocalAssetHelper].readFromPlist];
    }
    
    return _localAssetInfoMArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

//    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadAssets];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return self.localAssetsDict.allKeys.count;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHLocalAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"localAlbumCellID" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    // Configure the cell...

    UIView *backgroudViews = [[UIView alloc] initWithFrame:cell.frame];
    backgroudViews.backgroundColor = [UIColor ic_colorWithHex:kButtonThemeColor];
    [cell setSelectedBackgroundView:backgroudViews];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    cell.mediaType = (int)indexPath.row;
    
    cell.delegate = self;
    
    NSString *secondKey = @"photos";
    if(indexPath.row) {
        secondKey = @"videos";
    }
    
    NSMutableArray *assetsArray = [[self.localAssetsDict objectForKey:_cameraUid] objectForKey:secondKey];
    cell.assetsArray = assetsArray;

    return cell;
}

#pragma mark - UITableViewDelegate
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[SHCameraManager  sharedCameraManger] getSHCameraObjectWithCameraUid:_cameraUid].camera.cameraName;
}

#pragma mark - Load Assets
- (void)loadAssets {
    if (NSClassFromString(@"PHAsset")) {
        // Check library permissions
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    [self performLoadLocalAssets];
                }
            }];
        } else if (status == PHAuthorizationStatusAuthorized) {
            [self performLoadLocalAssets];
        }
    } else {
        // Assets library
        [self performLoadLocalAssets];
    }
}

- (void)performLoadLocalAssets {
    [self.localAssetsDict removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHFetchResult *assetsFetchResult = nil;
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (int i=0; i<topLevelUserCollections.count; ++i) {
            PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
            if ([collection.localizedTitle isEqualToString:kLocalAlbumName]) {
                if (![collection isKindOfClass:[PHAssetCollection class]]) {
                    continue;
                }
                // Configure the AAPLAssetGridViewController with the asset collection.
                PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                PHFetchOptions *options = [PHFetchOptions new];
                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
                break;
            }
        }
        
        if (!assetsFetchResult) {
            SHLogWarn(SHLogTagAPP, @"assetsFetchResult was nil.");
            return;
        }
        
        NSMutableDictionary *assetsDict = [NSMutableDictionary new];

        [assetsFetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            PHAsset *asset = obj;
            
            [self.localAssetInfoMArray enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *key = obj.allKeys.firstObject;
                NSMutableArray *detailArray = [NSMutableArray arrayWithArray:[obj objectForKey:key]];
                [detailArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([asset.localIdentifier isEqualToString:obj]) {
                        if (asset.mediaType == PHAssetMediaTypeImage) {
                            if ([assetsDict.allKeys containsObject:key]) {
                                NSMutableDictionary *rootDict = [NSMutableDictionary dictionaryWithDictionary:[assetsDict objectForKey:key]];

                                NSMutableArray *photos = [NSMutableArray arrayWithArray:rootDict[@"photos"]];
                                [photos addObject:asset];
                               
                                [rootDict setValue:photos forKey:@"photos"];
                                [assetsDict setValue:rootDict forKey:key];
                            } else {
                                [assetsDict setObject:@{@"photos":@[asset]} forKey:key];
                            }
                        } else if (asset.mediaType == PHAssetMediaTypeVideo) {
                            if ([assetsDict.allKeys containsObject:key]) {
                                NSMutableDictionary *rootDict = [NSMutableDictionary dictionaryWithDictionary:[assetsDict objectForKey:key]];
                                
                                NSMutableArray *videos = [NSMutableArray arrayWithArray:rootDict[@"videos"]];
                                [videos addObject:asset];
                                
                                [rootDict setValue:videos forKey:@"videos"];
                                [assetsDict setValue:rootDict forKey:key];
                            } else {
                                [assetsDict setObject:@{@"videos":@[asset]} forKey:key];
                            }
                        }
                    }
                }];
            }];
        }];
        
        SHLogInfo(SHLogTagAPP, @"assetsDict: %@", assetsDict);
        self.localAssetsDict = assetsDict;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}


#pragma mark -
- (void)localAlbumCell:(SHLocalAlbumCell *)cell showLocalMediaBrowser:(UINavigationController *)nav {
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)localAlbumCell:(SHLocalAlbumCell *)cell deleteLocalAssetWithIndex:(NSUInteger)index tag:(NSInteger)tag completionHandler:(nullable void(^)(BOOL success))completionHandler {
    __block NSIndexPath *indexPath = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        indexPath =  [self.tableView indexPathForCell:cell];
    });
    
    NSString *secondKey = @"photos";
    if(indexPath.row) {
        secondKey = @"videos";
    }
    
    NSMutableArray *assetsArray = [[self.localAssetsDict objectForKey:_cameraUid] objectForKey:secondKey];
    
    PHAsset *asset = assetsArray[index];
    
    if (asset == nil) {
        if (completionHandler) {
            completionHandler(NO);
        }
        
        return;
    }
    
    SHLogInfo(SHLogTagAPP, @"current index: %lu, assets count: %lu", (unsigned long)index, (unsigned long)assetsArray.count);
    WEAK_SELF(self);
    [[XJLocalAssetHelper sharedLocalAssetHelper] deleteLocalAsset:asset.localIdentifier forKey:self.cameraUid completionHandler:^(BOOL success) {
        // when assetsArray.count == 1, will call performLoadLocalAssets
        if (success && assetsArray.count > 1) {
            [assetsArray removeObjectAtIndex:index];
            
            NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.tableView reloadRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            });
        }
        
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

@end
