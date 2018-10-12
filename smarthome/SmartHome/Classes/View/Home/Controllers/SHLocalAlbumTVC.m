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
//    [self.tableView registerClass:[SHLocalAlbumCell class] forCellReuseIdentifier:@"localAlbumCellID"];
    self.automaticallyAdjustsScrollViewInsets = NO;
//    self.title = NSLocalizedString(@"Photos", nil);
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
#if 0
    NSString *key = self.localAssetsDict.allKeys[indexPath.section];
    
    NSString *secondKey = @"photos";
    if(indexPath.row) {
        secondKey = @"videos";
    }
    UIView *backgroudViews = [[UIView alloc] initWithFrame:cell.frame];
    backgroudViews.backgroundColor = [UIColor blueColor];
    [cell setSelectedBackgroundView:backgroudViews];
    cell.mediaType = indexPath.row;
    
    NSMutableArray *assetsArray = [[self.localAssetsDict objectForKey:key] objectForKey:secondKey];
    cell.assetsArray = assetsArray;
    
    [cell setShowLocalMediaBrowserBlock:^ (UINavigationController *nc){
        [self presentViewController:nc animated:YES completion:nil];
    }];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.deleteLocalFileBlock = ^BOOL(NSInteger tag, NSInteger index) {
        NSString *filePath = nil;
        NSArray *documentsDirectoryContents;
        
        if (tag == 0) {
            filePath = [SHTool createMediaDirectoryWithPath:key][1];
        } else {
            filePath = [SHTool createMediaDirectoryWithPath:key][2];
        }
        documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    
        BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", filePath, documentsDirectoryContents[index]] error:nil];
        if (ret) {

            if (tag == 0) {
                NSMutableArray *photoAsstes = assetsArray;
                [photoAsstes removeObjectAtIndex:index];
            } else {
                NSMutableArray *videoAsstes = assetsArray;
                [videoAsstes removeObjectAtIndex:index];
            }
            
            NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            });
        }
        
        return ret;
    };
#endif

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
#if 1
//    return self.localAssetsDict.allKeys[section];
    return [[SHCameraManager  sharedCameraManger] getSHCameraObjectWithCameraUid:_cameraUid].camera.cameraName;
#else
    NSArray *camobjs = [[SHCameraManager  sharedCameraManger] smarthomeCams];
    NSString *uidMd5 = self.localAssetsDict.allKeys[section];
    for(SHCameraObject *camobj in camobjs) {
        SHCamera *camera = camobj.camera;
        if( [uidMd5 compare:camera.cameraUid.md5] == 0) {
            return camera.cameraName;
        }
    }
    return @"Unknown";
#endif
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
    
#if 0
    // Load
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"SmartHome-Medias"];
        NSArray *dirArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mediaDirectory error:nil];
        SHLogDebug(SHLogTagAPP, @"dirArray: %@", dirArray);
        
        for (NSString *path in dirArray) {
            
//            if (![path isEqualToString:_cameraUid.md5]) {
//                continue;
//            }
            
            // photo
            NSString *photosPath = [SHTool createMediaDirectoryWithPath:path][1];
            NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:photosPath error:nil];
            
            NSMutableArray *photosAssets = [[NSMutableArray alloc] initWithCapacity:documentsDirectoryContents.count];
            for (NSString *photoPath in documentsDirectoryContents) {
                [photosAssets addObject:[NSURL fileURLWithPath:[photosPath stringByAppendingPathComponent:photoPath]]];
            }
            
            SHLogInfo(SHLogTagAPP, @"_photosAssets.count: %lu", (unsigned long)photosAssets.count);
            
            // video
            NSString *videosPath = [SHTool createMediaDirectoryWithPath:path][2];
            NSArray *videoDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videosPath error:nil];
            
            NSMutableArray *videosAssets = [[NSMutableArray alloc] initWithCapacity:videoDocuments.count];
            for (NSString *videoPath in videoDocuments) {
                [videosAssets addObject:[NSURL fileURLWithPath:[videosPath stringByAppendingPathComponent:videoPath]]];
            }
            
            SHLogInfo(SHLogTagAPP, @"_videosAssets.count: %lu", (unsigned long)videosAssets.count);
            [self.localAssetsDict setObject:@{@"photos":photosAssets, @"videos":videosAssets} forKey:path];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
#else
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
#endif
}


#pragma mark -
- (void)localAlbumCell:(SHLocalAlbumCell *)cell showLocalMediaBrowser:(UINavigationController *)nav {
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
    
    [[XJLocalAssetHelper sharedLocalAssetHelper] deleteLocalAsset:asset.localIdentifier forKey:self.cameraUid completionHandler:^(BOOL success) {
        if (success) {
            if (tag == 0) {
                NSMutableArray *photoAsstes = assetsArray;
                [photoAsstes removeObjectAtIndex:index];
            } else {
                NSMutableArray *videoAsstes = assetsArray;
                [videoAsstes removeObjectAtIndex:index];
            }
            
            NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            });
        }
        
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

@end
