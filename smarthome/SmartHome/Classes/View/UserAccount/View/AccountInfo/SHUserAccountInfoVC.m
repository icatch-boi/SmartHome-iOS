// SHUserAccountInfoVC.m

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
 
 // Created by zj on 2018/5/2 下午5:06.
    

#import "SHUserAccountInfoVC.h"
#import "UIViewController+CWLateralSlide.h"
#import "SHAccountTableViewCell.h"
#import "SHAccountInfoHeaderView.h"
#import "SHUserAccountItem.h"
#import "SHMessagesListTVC.h"
#import "SHAccountSettingTVC.h"
#import "SHNetworkManagerHeader.h"
#import "SHUserAccountInfoTVC.h"
#import "SHAppInfoVC.h"
#import <MessageUI/MessageUI.h>
#import "UserAccountPortraitNavVC.h"

static NSString * const kAccountCellID = @"AccountCellID";
static const NSUInteger kHeaderViewHeight = 200;
static NSString * const kJSONFileName = @"userAccountItem.json";
static const CGFloat kTableViewRowHeight = 60;

@interface SHUserAccountInfoVC () <UITableViewDelegate, UITableViewDataSource, SHAccountInfoHeaderViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSArray *itemsArray;

@property (nonatomic, weak) SHAccountInfoHeaderView *headerView;

@end

@implementation SHUserAccountInfoVC

#pragma mark prepare Data
- (NSArray *)itemsArray {
    if (_itemsArray == nil) {
//        @[@{@"index" : @0, @"iconName" : @"ic_alarm_red_400_36dp", @"title" : @"Message", @"methodName" : @"enterMessageList" },
//          @{@"index" : @1, @"iconName" : @"ic_perm_identity_36dp", @"title" : @"Setting", @"methodName" : @"enterSetting"},
//          ];
        NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *jsonPath = [docDir stringByAppendingPathComponent:kJSONFileName];
        
        NSData *data = [[NSData alloc] initWithContentsOfFile:jsonPath];
        
        if (data == nil) {
            NSString *path = [[NSBundle mainBundle] pathForResource:kJSONFileName ofType:nil];
            data = [[NSData alloc] initWithContentsOfFile:path];
        }
        
        NSArray *tempArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (tempArray == nil) {
            SHLogError(SHLogTagAPP, @"Serialization is failed.");
            _itemsArray = [NSArray array];
        } else {
            NSMutableArray *tempMArray = [[NSMutableArray alloc] initWithCapacity:tempArray.count];
            [tempArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHUserAccountItem *item = [SHUserAccountItem userAccountItemWithDict:obj];
                if (item) {
                    [tempMArray addObject:item];
                }
            }];
            
            _itemsArray = tempMArray.copy;
        }
    }
    
    return _itemsArray;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - init
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupHeaderView];
    [self setupTableView];
}

- (void)viewWillLayoutSubviews {
    _headerView.nickName = SHNetworkManager.sharedNetworkManager.userAccount.screen_name;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupHeaderView {
    SHAccountInfoHeaderView *view = [SHAccountInfoHeaderView accountInfoHeaderViewWithFrame:CGRectMake(0, 0, kCWSCREENWIDTH * 0.75, kHeaderViewHeight)];
    
    view.nickName = SHNetworkManager.sharedNetworkManager.userAccount.screen_name; //@"大🍉";
//    view.avatorImage = [UIImage imageNamed:@"portrait-1"];
    NSString *avatorName = SHNetworkManager.sharedNetworkManager.userAccount.avatar_large;
    SHLogInfo(SHLogTagAPP, @"avatar: %@" , avatorName);
    view.avatorName = avatorName;
    view.delegate = self;
//    view.backgroundColor = [UIColor ic_colorWithRed:66 green:137 blue:235 alpha:1.0];
    
    [self.view addSubview:view];
    _headerView = view;
}

- (void)setupTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kHeaderViewHeight, kCWSCREENWIDTH * 0.75, CGRectGetHeight(self.view.bounds) - kHeaderViewHeight) style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.rowHeight = kTableViewRowHeight;
    [self.view addSubview:tableView];
    [tableView registerNib:[UINib nibWithNibName:@"AccountTableViewCell" bundle:nil] forCellReuseIdentifier:kAccountCellID];
    tableView.backgroundColor = [UIColor ic_colorWithHex:kThemeColor];
    tableView.tableFooterView = [self tableFooterView];

    _tableView = tableView;
}

- (UIView *)tableFooterView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCWSCREENWIDTH * 0.75, 50)];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leftbar-logo"]];
    imageView.center = view.center;
    
    [view addSubview:imageView];
    
    return view;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kAccountCellID forIndexPath:indexPath];
    
    SHUserAccountItem *item = self.itemsArray[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIView *backgroundViews = [[UIView alloc] initWithFrame:cell.frame];
    backgroundViews.backgroundColor = [UIColor whiteColor];
    
    [cell setSelectedBackgroundView:backgroundViews];
    cell.titleLabel.highlightedTextColor = [UIColor blueColor];
    cell.selectedBackgroundView.backgroundColor = [UIColor whiteColor];
    
    cell.item = item;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
    
    SHUserAccountItem *item = self.itemsArray[indexPath.row];
    SEL method = NSSelectorFromString(item.methodName);
    if ([self respondsToSelector:method]) {
        [self performSelector:method withObject:item afterDelay:0];
    }
}


- (void)enterMyCameras {
#if 0
    SHMessagesListTVC *vc = [SHMessagesListTVC messageListTVC];
    vc.managedObjectContext = _managedObjectContext;
    vc.title = item.title;
    
    [self cw_pushViewController:vc drewerHiddenDuration:0];
#endif
//    [self dismissViewControllerAnimated:YES completion:nil];
    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] closeLeftMenu];
}

- (void)enterSuggestion:(SHUserAccountItem *)item {
#if 0
    UIViewController *vc = [[UIViewController alloc] init];
    vc.title = item.title;
    vc.view.frame = self.view.frame;
    vc.view.backgroundColor = [UIColor whiteColor];

    [self cw_pushViewController:vc drewerHiddenDuration:0];
#endif
    [self newEmail];
}

- (void)enterAccount:(SHUserAccountItem *)item {
    SHUserAccountInfoTVC *vc = [SHUserAccountInfoTVC userAccountInfoTVC];
    vc.title = item.title;
    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil target:[ZJSlidingDrawerViewController sharedSlidingDrawerVC] action:@selector(popViewController) isBack:YES];
    
    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] pushViewController:vc];
}

- (void)enterAbout:(SHUserAccountItem *)item {
#if 0
    SHAccountSettingTVC *vc = [SHAccountSettingTVC accountSettingTVC];
    vc.title = item.title;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
#endif
    SHAppInfoVC *vc = [SHAppInfoVC appInfoVC];
    vc.title = item.title;
    
//    [self cw_pushViewController:vc drewerHiddenDuration:0];
//    [self presentViewController:nav animated:YES completion:nil];
    
#if 0
    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:[ZJSlidingDrawerViewController sharedSlidingDrawerVC] action:@selector(popViewController) isBack:NO];
    
    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] pushViewController:vc];
#endif
    [self presentViewController:[[UserAccountPortraitNavVC alloc] initWithRootViewController:vc] animated:YES completion:nil];
}

#pragma mark -
- (void)enterAccountWithHeaderView:(SHAccountInfoHeaderView *)headerView {
#if 0
    SHUserAccountInfoTVC *vc = [SHUserAccountInfoTVC userAccountInfoTVC];
    
//    [self cw_pushViewController:vc drewerHiddenDuration:0];
    
    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil target:[ZJSlidingDrawerViewController sharedSlidingDrawerVC] action:@selector(retunbackHome) isBack:YES];

    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] pushViewController:vc];
#endif
}

- (NSString *)deviceInfo {
    NSString *userPhoneNameStr = [[UIDevice currentDevice] name];//手机名称
    NSString *systemVersionStr = [[UIDevice currentDevice] systemVersion];//手机系统版本号
    
    NSString *deviceInfo = [NSString stringWithFormat:@"iPhone OS %@ (%@)", systemVersionStr, userPhoneNameStr];
    NSLog(@"deviceInfo: %@", deviceInfo);
    
    return deviceInfo;
}

- (NSString *)appInfo {
    NSString *appInfo = [NSString stringWithFormat:@"App Version: %@ (%@)", APP_VERSION, APP_BUILDNUMBER];
    NSLog(@"appInfo: %@", appInfo);
    
    return appInfo;
}

#pragma mark - email
- (void)newEmail {
    //建立物件與指定代理
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    if (controller == nil) {
        return;
    }
    
    controller.mailComposeDelegate = self;
    NSString *email = @"yiwei.wu@szxiaojun.com";
    
    //設定收件人與主旨等資訊
    [controller setToRecipients:[NSArray arrayWithObjects:email, nil]];
    [controller setSubject:@"Support for (Troubleshooting)"];
    
    //設定內文並且不使用HTML語法
//    NSString *msg = [NSString stringWithFormat:@"Welcome<BR><br>SmartHome want to share a new door bell camera to you.<BR>You should install <B>iCatch SmartHome APP</B> from Apple Store or Google Play.<BR><BR>After install completed, launch the app and tape + on the title bar to add camera.<BR><BR>There are two way for you to add camera.<BR><BR>1. Scan QR code.<BR>2. Manually input this code."];
    
    NSString *msg = [NSString stringWithFormat:@"<BR><BR><BR><BR> <B>%@</B> <BR> <B>%@</B>", [self appInfo], [self deviceInfo]];
    [controller setMessageBody:msg isHTML:YES];
    
    //加入圖片
    //UIImage *theImage = [UIImage imageNamed:@"image.png"];
    //NSData *imageData = UIImagePNGRepresentation(self.qrImage.image);
#if 0
    NSData *jpegData = UIImageJPEGRepresentation(self.qrImage.image, 1.0);
    [controller addAttachmentData:jpegData mimeType:@"image/jpeg" fileName:@"image.jpg"];
#endif
    
    //顯示電子郵件畫面
    [self presentViewController:controller animated:YES completion:nil];
}

//此為內建函式
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
