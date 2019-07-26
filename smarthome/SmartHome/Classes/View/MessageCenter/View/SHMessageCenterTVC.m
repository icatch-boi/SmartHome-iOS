// SHMessageCenterTVC.m

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
 
 // Created by zj on 2019/7/26 3:29 PM.
    

#import "SHMessageCenterTVC.h"
#import "SHMessageCell.h"

static NSString * const kMessageCellID = @"MessageCellID";

@interface SHMessageCenterTVC ()

@end

@implementation SHMessageCenterTVC

+ (instancetype)messageCenterTVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MessageCenter" bundle:nil];
    return [sb instantiateInitialViewController];
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
    self.tableView.backgroundColor = [UIColor ic_colorWithHex:kBackgroundThemeColor];
    self.tableView.rowHeight = 100;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageCellID forIndexPath:indexPath];
    
    // Configure the cell...
    cell.iconImgView.image = [UIImage imageNamed:@"portrait"];
    cell.titleLabel.text = @(indexPath.section).stringValue;
    cell.timeLabel.text = @(indexPath.row).stringValue;
    
    return cell;
}



@end
