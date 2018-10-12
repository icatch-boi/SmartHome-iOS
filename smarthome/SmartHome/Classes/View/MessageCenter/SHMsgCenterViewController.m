// SHMsgCenterViewController.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by sa on 2018/3/30 下午5:43.
    

#import "SHMsgCenterViewController.h"
#import "SHMsgFileViewController.h"
#import "MessageCenter.h"
#import "MessageInfo.h"
#import "SHFileOperation.h"
#import "SHMsgInfoTableViewCell.h"

@interface SHMsgCenterViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *msgTableView;
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
@property (weak, nonatomic) IBOutlet UIView *editView;

- (IBAction)editAction:(UIButton *)sender;
- (IBAction)selectAllAction:(UIButton *)sender;
- (IBAction)deleteAction:(UIButton *)sender;

@property (nonatomic) BOOL selecting;
@property (nonatomic) BOOL allSelected;
@property (nonatomic, strong) NSMutableArray *sourceArr;
@property  NSMutableArray *selectedArr;
@property (nonatomic, strong) MessageCenter *msgCenter;
@end

@implementation SHMsgCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _msgTableView.delegate = self;
    _msgTableView.dataSource = self;
    _selecting = NO;
    _allSelected = NO;
    [_editView setHidden:YES];
    self.selectedArr = [NSMutableArray new];
    //[_msgTableView setRowHeight:50];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSMutableArray *)sourceArr
{
    if(_sourceArr == nil) {
        if(_msgCenter == nil) {
            _msgCenter = [[MessageCenter alloc] initWithName:_uuid andMSGDelegate:[SHFileOperation new]];
        }
        if (_msgCenter) {
            int msgCount = [_msgCenter getMessageCount];
            NSArray* tmpArr = [_msgCenter getMessageWithStartIndex:0 andCount:msgCount];
            if (tmpArr != nil) {
                self.sourceArr = [NSMutableArray new];
                [_sourceArr addObjectsFromArray:tmpArr];
            }
        }
    }
    return _sourceArr;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowCnt = self.sourceArr.count;
    return rowCnt;
}

- (SHMsgInfoTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"msgInfoCellID";
    SHMsgInfoTableViewCell* cell = [self.msgTableView dequeueReusableCellWithIdentifier:cellID];
//    if(cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
//    }
//    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    MessageInfo *msgInfo = [self.sourceArr objectAtIndex:indexPath.row];
    NSString *imgName = msgInfo.getMsgType == 201 ? @"ic_notifications_black_24dp" : @"ic_pir_detecting_24dp";
    NSString *titleName = msgInfo.getMsgType == 201 ? @"Front Door" : @"Living Room";
    
//    cell.imageView.image = [UIImage imageNamed:imgName];
//    cell.textLabel.text =titleName;
//    cell.detailTextLabel.text = msgInfo.getMsgDatetime;
    cell.imageView.image = [UIImage imageNamed:imgName];
//    cell.iconImgView.image =
    cell.msgTypeView.text = titleName;
    cell.timeView.text = msgInfo.getMsgDatetime;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //在编辑状态 选中当前
    if(_selecting) {
        [self.selectedArr addObject:[self.sourceArr objectAtIndex:indexPath.row]];
        return ;
    }
    //未在编辑状态，跳转到filelist view
    UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:kMessageCenterStoryboardName bundle:nil];
    SHMsgFileViewController *msgFileVC = [mainBoard instantiateViewControllerWithIdentifier:@"fileInfo"];
    msgFileVC.uuid = _uuid;
    msgFileVC.msgInfo = [self.sourceArr objectAtIndex:indexPath.row];
    msgFileVC.msgCenter = _msgCenter;
    [self.navigationController pushViewController:msgFileVC animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{

    //在编辑状态，取消选中的cell.
    if(_selecting) {
        [self.selectedArr removeObject:[self.sourceArr objectAtIndex:indexPath.row]];
    }
    return ;
}

- (IBAction)editAction:(UIButton *)sender {
    _selecting = !_selecting;
    //显示可操作的视图"全选、删除"
    [_editView setHidden:!_selecting];
    
    NSString *title = _selecting ? @"Cancel" : @"Edit";
    [_editBtn setTitle:title forState:UIControlStateNormal];
    
    //当执行取消时，应该把选中的单元格的数据清空
    if(!_selecting) {
        [self.selectedArr removeAllObjects];
        if (self.allSelected == YES) {
            self.allSelected = NO;
        }
    }
    
    //表格的编辑状态
    self.msgTableView.allowsMultipleSelectionDuringEditing = _selecting;
    self.msgTableView.editing = !self.msgTableView.editing;
}

- (IBAction)selectAllAction:(UIButton *)sender {
    
    if(self.selectedArr.count > 0) {
        [self.selectedArr removeAllObjects];
    }
    self.allSelected = !self.allSelected;
    for (int i = 0; i < self.sourceArr.count; i++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        if (self.allSelected == NO) {
            [self.msgTableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            [self.msgTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
        }
    }
    if (self.allSelected == YES) {
        [self.selectedArr addObjectsFromArray:self.sourceArr];
    }
}

- (IBAction)deleteAction:(UIButton *)sender {
    NSLog(@"select:%@", self.selectedArr);
    NSLog(@"source:%@", self.sourceArr);
    [_sourceArr removeObjectsInArray:_selectedArr];
    NSLog(@"delete source : %@", _sourceArr);
    
    for (int i = 0; i < _selectedArr.count; i++) {
        MessageInfo *info = [_selectedArr objectAtIndex:i];
        [_msgCenter deleteMessageWithMessageInfo:info];
    }
    [self.selectedArr removeAllObjects];
    [self.msgTableView reloadData];
}
@end
