//
//  SHFileDownloadTVC.m
//  SmartHome
//
//  Created by ZJ on 2017/6/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHFileDownloadTVC.h"
#import "SHDownloadTableViewCell.h"
#import "SHDownloadManager.h"
#import "SHLocalAlbumTVC.h"

@interface SHFileDownloadTVC () <SHDownloadAboutInfoDelegate>

@property (weak, nonatomic) IBOutlet UILabel *downloadInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *detailInfoButton;
@property (atomic, strong) NSMutableArray *downloadArray;

@property (nonatomic) MBProgressHUD *progressHUD;



@end

@implementation SHFileDownloadTVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    SHCameraManager *app = [SHCameraManager sharedCameraManger];
//    self.shCamObj = [app.smarthomeCams objectAtIndex:0];
//    self.shCamObj = [app getSHCameraObjectWithCameraUid:_cameraUid];
//    self.ctrl = _shCamObj.controler;
	
 	self.downloadArray = [SHDownloadManager shareDownloadManger].downloadArray;
	SHLogInfo(SHLogTagAPP, "viewDidLoad cout is : %d",self.downloadArray.count);
	[SHDownloadManager shareDownloadManger].downloadInfoDelegate = self;
    [self updateDownloadInfo];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recoverFromDisconnection) name:kCameraNetworkConnectedNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraNetworkConnectedNotification object:nil];
}

- (void)recoverFromDisconnection {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)updateDownloadInfo {
	int downloadSuccessedNum = [SHDownloadManager shareDownloadManger].downloadSuccessedNum;
	int downloadFailedNum = [SHDownloadManager shareDownloadManger].downloadFailedNum;
	int cancelDownloadNum = [SHDownloadManager shareDownloadManger].cancelDownloadNum;
    self.downloadInfoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"kFileDownloadInfo", nil), downloadSuccessedNum, downloadFailedNum, cancelDownloadNum];
}

- (IBAction)showDownloadDetailInfo:(id)sender {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:kAlbumStoryboardName bundle:nil];

    SHLocalAlbumTVC *tvc = [mainStoryboard instantiateViewControllerWithIdentifier:@"LocalAlbumSBID"];
    tvc.cameraUid = _cameraUid;
    
    [self.navigationController pushViewController:tvc animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSLog(@"downloadArray count is %d ",self.downloadArray.count);
	//NSLog(@"tableView count is %d ",[tableView numberOfRowsInSection:(0)]);
	SHLogInfo(SHLogTagAPP, "tableView cout is : %d",self.downloadArray.count);
    return self.downloadArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHDownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadCellID" forIndexPath:indexPath];
	cell.file = self.downloadArray[indexPath.row];
//	cell.shCamObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:cell.file.uid];
//	
//	[cell setDownloadCompleteBlock:^ (SHDownloadTableViewCell *dcell) {
//		NSIndexPath *curIndexPath = [tableView indexPathForCell:dcell];
//		
//		switch (dcell.downloadInfo) {
//			case 0:
//				break;
//				
//			default:
//				break;
//		}
//		
//		dispatch_async(dispatch_get_main_queue(), ^{
//			NSLog(@"........downloadArray count is %d ",self.downloadArray.count);
//			if (curIndexPath) {
//				//[self.downloadArray removeObjectAtIndex:curIndexPath.row];
//				if (!self.downloadArray.count) {
//					if (self.downloadCompleteBlock) {
//						self.downloadCompleteBlock();
//					}
//				}
//				
//				[tableView deleteRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//			}
//			
//			if (self.downloadArray.count > 0) {
//				NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//				[tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//			}
//			self.downloadSuccessedNum++;
//			[self updateDownloadInfo];
//		});
//	}];
//	
//	[cell setCancelDownloadSuccessBlock:^ (SHDownloadTableViewCell *dcell){
//		SHLogInfo(SHLogTagAPP, @"cancel success.");
//		//need delete file from download array
//		[self.downloadArray removeObject:dcell.file];
//		//[dcell download
//		dispatch_async(dispatch_get_main_queue(), ^{
//			[self.progressHUD hideProgressHUD:YES];
//			[self.tableView reloadData];
//			self.cancelDownloadNum++;
//			[self updateDownloadInfo];
//			
//		});
//	}];
//	
//	[cell setCancelDownloadFailedBlock:^{
//		SHLogError(SHLogTagAPP, @"cancel failed.");
//		dispatch_async(dispatch_get_main_queue(), ^{
//			[self.progressHUD showProgressHUDNotice:@"cancel failed." showTime:1.5];
//			self.downloadFailedNum++;
//			[self updateDownloadInfo];
//		});
//	}];
//	
//	[cell setCancelDownloadPrepareBlock:^{
//		[self.progressHUD showProgressHUDWithMessage:@"正在取消下载..."];
//	}];
//	SHLogInfo(SHLogTagAPP, @"cell: %@", cell);
	return cell;


    // Configure the cell...
//    cell.file = self.downloadArray[indexPath.row];
//    cell.shCamObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:cell.file.uid];
//	
//    [cell setDownloadCompleteBlock:^ (SHDownloadTableViewCell *dcell) {
//        NSIndexPath *curIndexPath = [tableView indexPathForCell:dcell];
//        
//        switch (dcell.downloadInfo) {
//            case 0:
//                break;
//                
//            default:
//                break;
//        }
//        
//		dispatch_async(dispatch_get_main_queue(), ^{
//			NSLog(@"........downloadArray count is %d ",self.downloadArray.count);
//			if (curIndexPath) {
//				//[self.downloadArray removeObjectAtIndex:curIndexPath.row];
//				if (!self.downloadArray.count) {
//					if (self.downloadCompleteBlock) {
//						self.downloadCompleteBlock();
//					}
//				}
//				
//				[tableView deleteRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//			}
//			
//			if (self.downloadArray.count > 0) {
//				NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//				[tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//			}
//			self.downloadSuccessedNum++;
//			[self updateDownloadInfo];
//		});
//	}];
//	
//    [cell setCancelDownloadSuccessBlock:^ (SHDownloadTableViewCell *dcell){
//        SHLogInfo(SHLogTagAPP, @"cancel success.");
//		//need delete file from download array
//		[self.downloadArray removeObject:dcell.file];
//		//[dcell download
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.progressHUD hideProgressHUD:YES];
//			[self.tableView reloadData];
//			self.cancelDownloadNum++;
//			[self updateDownloadInfo];
//
//        });
//    }];
//    
//    [cell setCancelDownloadFailedBlock:^{
//        SHLogError(SHLogTagAPP, @"cancel failed.");
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.progressHUD showProgressHUDNotice:@"cancel failed." showTime:1.5];
//			self.downloadFailedNum++;
//			[self updateDownloadInfo];
//        });
//    }];
//    
//    [cell setCancelDownloadPrepareBlock:^{
//        [self.progressHUD showProgressHUDWithMessage:@"正在取消下载..."];
//    }];
//    SHLogInfo(SHLogTagAPP, @"cell: %@", cell);
//    return cell;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
    }
    
    return _progressHUD;
}

#pragma mark - SHDownloadAboutInfoDelegate
- (void)onDownloadComplete:(int)position retValue:(Boolean)ret{
	
	NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:position inSection:0];
	SHDownloadTableViewCell *cell = [self.tableView cellForRowAtIndexPath:curIndexPath];
	[self.tableView deleteRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self updateDownloadInfo];
}

- (void)onCancelDownloadComplete:(int)position retValue:(Boolean)ret{
	NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:position inSection:0];
	SHDownloadTableViewCell *cell = [self.tableView cellForRowAtIndexPath:curIndexPath];
	[self.tableView deleteRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
	if(ret == YES){
		SHLogInfo(SHLogTagAPP, @"cancel success.");
	}else{
		SHLogError(SHLogTagAPP, @"cancel failed.");
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.progressHUD showProgressHUDNotice:@"cancel failed." showTime:1.5];
			[self updateDownloadInfo];
		});
	}
	[self updateDownloadInfo];
}

- (void)onProgressUpdate:(int)position progress:(int)progress{
	NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:position inSection:0];
	SHDownloadTableViewCell *cell = [self.tableView cellForRowAtIndexPath:curIndexPath];
	[cell updateProgress:progress];
}

- (void)onAllDownloadComplete{
	
}

@end
