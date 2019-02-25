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

@interface SHFileDownloadTVC () <SHDownloadAboutInfoDelegate, SHDownloadTableViewCellDelegate>

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
	
 	self.downloadArray = [SHDownloadManager shareDownloadManger].downloadArray;
    SHLogInfo(SHLogTagAPP, "viewDidLoad cout is : %lu",(unsigned long)self.downloadArray.count);
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
    SHLogInfo(SHLogTagAPP, "tableView cout is : %lu",(unsigned long)self.downloadArray.count);
    return self.downloadArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHDownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadCellID" forIndexPath:indexPath];
	cell.file = self.downloadArray[indexPath.row];
    cell.delegate = self;

	return cell;
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
	[self.tableView deleteRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self updateDownloadInfo];
}

- (void)onCancelDownloadComplete:(int)position retValue:(Boolean)ret{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideProgressHUD:YES];
    });
    
	NSIndexPath *curIndexPath = [NSIndexPath indexPathForRow:position inSection:0];
	[self.tableView deleteRowsAtIndexPaths:@[curIndexPath] withRowAnimation:UITableViewRowAnimationFade];
	if(ret == YES){
		SHLogInfo(SHLogTagAPP, @"cancel success.");
	}else{
		SHLogError(SHLogTagAPP, @"cancel failed.");
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.progressHUD showProgressHUDNotice:/*@"cancel failed."*/NSLocalizedString(@"kCancelDownloadFailed", nil) showTime:1.5];
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

#pragma mark - SHDownloadTableViewCellDelegate
- (void)cancelDownloadHandler:(SHDownloadTableViewCell *)cell {
    [self.progressHUD showProgressHUDWithMessage:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SHDownloadManager shareDownloadManger] cancelDownloadFile:cell.file];
    });
}

@end
