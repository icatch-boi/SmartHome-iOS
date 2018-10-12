//
//  SHShareHomeTVC.m
//  SmartHome
//
//  Created by ZJ on 2018/3/7.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHShareHomeTVC.h"
#import "SHShareHomeHeaderView.h"
#import "SHShareWayViewController.h"
#import "SHNetworkManagerHeader.h"
#import "SHShareHomeCell.h"

static const CGFloat kHeaderViewHeight = 240;
static const CGFloat kShareCameraCellHeight = 50;
static const CGFloat kSharedCellHeight = 90;

@interface SHShareHomeTVC ()

@property (nonatomic, strong) NSMutableArray *subscriberMArray;
@property (nonatomic) MBProgressHUD *progressHUD;

@end

@implementation SHShareHomeTVC

+ (instancetype)shareHomeViewController {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:kUserAccountStoryboardName bundle:nil];
    return [mainStory instantiateViewControllerWithIdentifier:@"SHShareHomeTVCID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self setupGUI];
}

- (void)setupGUI {
    self.tableView.tableHeaderView = [SHShareHomeHeaderView shareHomwHeaderView:CGRectMake(0, 0, self.view.bounds.size.width, kHeaderViewHeight)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self getCameraSubscribers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.subscriberMArray.count ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section ? self.subscriberMArray.count : 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *shareCameraCellReuseID = @"shareCameraCellReuseID";
    static NSString *sharerCellReuseID = @"sharerCellReuseID";
    SHShareHomeCell *cell = nil;
    
    if (indexPath.section == 0) {
       cell = [tableView dequeueReusableCellWithIdentifier:shareCameraCellReuseID forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:sharerCellReuseID forIndexPath:indexPath];
        if (indexPath.row < self.subscriberMArray.count) {
            cell.subscriber = self.subscriberMArray[indexPath.row];
        }
    }
    
    // Configure the cell...
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section ? @"相机已分享给:" : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section ? kSharedCellHeight : kShareCameraCellHeight;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2ShareWayViewControllerID"]) {
        SHShareWayViewController *vc = [segue destinationViewController];
        vc.camera = _camera;
    }
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return indexPath.section ? YES : NO;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self removeCameraSubscriberAtIndex:indexPath.row completion:^{
            if (self.subscriberMArray.count) {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            }
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section ? @"取消分享" : nil;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *rowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        // todo
    }];
    rowAction.backgroundColor = [UIColor purpleColor];
    
    UITableViewRowAction *rowaction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"置顶" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
    }];
    rowaction.backgroundColor = [UIColor grayColor];
        
    return nil; //@[rowAction,rowaction];
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSMutableArray *)subscriberMArray {
    if (_subscriberMArray == nil) {
        _subscriberMArray = [NSMutableArray array];
    }
    
    return _subscriberMArray;
}

- (void)getCameraSubscribers {
    if (_camera.id == nil) {
        SHLogError(SHLogTagAPP, @"cameraId must not be nil.");
        return;
    }
    
    WEAK_SELF(self);
    [self.progressHUD showProgressHUDWithMessage:@"正在获取订阅者信息..."];
    [[SHNetworkManager sharedNetworkManager] getCameraSubscribersWithCameraID:_camera.id status:0x100 completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            [weakself.subscriberMArray removeAllObjects];
            [weakself.subscriberMArray addObjectsFromArray:result];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];

                [weakself.tableView reloadData];
            });
        } else {
            Error *error = result;
            weakself.progressHUD.detailsLabelText = error.error_description;
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD showProgressHUDNotice:@"获取订阅者信息失败" showTime:2.0];
            });
        }
    }];
}

- (void)removeCameraSubscriberAtIndex:(NSUInteger)index completion:(void (^)())completion {
    if (_camera.id == nil) {
        SHLogError(SHLogTagAPP, @"cameraId must not be nil.");
        return;
    }
    
    if (index < self.subscriberMArray.count) {
        Subscriber *subscriber = self.subscriberMArray[index];
        
        WEAK_SELF(self);
        [self.progressHUD showProgressHUDWithMessage:@"正在取消分享..."];
        [[SHNetworkManager sharedNetworkManager] removeCameraSubscriberWithCameraID:_camera.id userID:subscriber.userId completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                [weakself.subscriberMArray removeObject:subscriber];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                    
                    if (completion) {
                        completion();
                    }
                });
            } else {
                Error *error = result;
                weakself.progressHUD.detailsLabelText = error.error_description;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD showProgressHUDNotice:@"取消分享失败" showTime:2.0];
                });
            }
        }];
    }
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view];
    }
    
    return _progressHUD;
}

@end
