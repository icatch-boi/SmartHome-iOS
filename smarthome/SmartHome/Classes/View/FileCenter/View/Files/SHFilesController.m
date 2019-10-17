//
//  SHFilesController.m
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "SHFilesController.h"
#import "SHFilesCell.h"
#import "SHENetworkManagerCommon.h"

@interface SHFilesController ()

@property (nonatomic, strong) NSArray<SHS3FileInfo *> *filesList;

@end

@implementation SHFilesController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    self.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256) / 255.0 green:arc4random_uniform(256) / 255.0 blue:arc4random_uniform(256) / 255.0 alpha:1.0];
    self.tableView.rowHeight = [self calcRowHeight];
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (CGFloat)calcRowHeight {
    CGFloat screenW = [[UIScreen mainScreen] bounds].size.width;
    NSInteger space = 4;
    
    CGFloat imgViewW = screenW  * 0.4;
    CGFloat imgViewH = imgViewW * 9 / 16;
    
    CGFloat rowH = imgViewH + space * 2;
    
    return rowH;
}

- (void)setDateFileInfo:(SHDateFileInfo *)dateFileInfo {
    _dateFileInfo = dateFileInfo;
    
    self.filesList = nil;
    
    WEAK_SELF(self);
    [[SHENetworkManager sharedManager] listFilesWithDeviceID:dateFileInfo.deviceID queryDate:dateFileInfo.date startKey:nil number:0 completion:^(NSArray<SHS3FileInfo *> * _Nullable filesInfo) {
        weakself.filesList = filesInfo;
    }];
}

- (void)setFilesList:(NSArray<SHS3FileInfo *> *)filesList {
    _filesList = filesList;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHFilesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"files" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.dateFileInfo = self.dateFileInfo;
    cell.fileInfo = self.filesList[indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectRowAtIndexPath");
}

@end
