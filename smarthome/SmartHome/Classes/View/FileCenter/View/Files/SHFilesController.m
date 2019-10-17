//
//  SHFilesController.m
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "SHFilesController.h"
#import "SHFilesCell.h"

@interface SHFilesController ()

@property (nonatomic, strong) NSArray *filesList;

@end

@implementation SHFilesController

- (NSArray *)filesList {
    if (_filesList == nil) {
        _filesList = @[@"1", @"2"];
    }
    
    return _filesList;
}

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
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHFilesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"files" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.dateFileInfo = self.dateFileInfo;
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectRowAtIndexPath");
}

@end
