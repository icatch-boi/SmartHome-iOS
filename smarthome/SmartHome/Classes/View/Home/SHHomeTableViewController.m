// SHHomeTableViewController.m

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
 
 // Created by zj on 2018/3/21 下午2:10.
    

#import "SHHomeTableViewController.h"
#import "SHCameraListViewModel.h"
#import "SHCameraViewCell.h"
#import "SHSetupNavVC.h"
#import "SHCameraPreviewVC.h"
#import "SHShareCameraViewController.h"
#import "SHMsgCenterViewController.h"
#import "SHLocalAlbumTVC.h"
#import "SHUserAccountHeader.h"
#import "SHLocalWithRemoteHelper.h"
#import "UIViewController+CWLateralSlide.h"
#import "SHUserAccountInfoVC.h"
#import "SHMessagesListTVC.h"
#import "SHQRCodeShareVC.h"
#import "XJMessageCenterViewController.h"
#import "MessageCenter.h"
#import "SHQRCodeScanningVC.h"
#import "SHPushTestNavController.h"
//#import "XJLocalAssetHelper.h"
#import "AppDelegate.h"

#define useAccountManager 1
static NSString * const kCameraViewCellID = @"CameraViewCellID";
//static const CGFloat kCameraTitleHeight = 30;
static NSString * const kSetupStoryboardID = @"SetupNavVCSBID";

@interface SHHomeTableViewController () <SHCameraViewCellDelegate, SHLoginViewDelegate>

@property (nonatomic, strong) SHCameraListViewModel *listViewModel;
@property (nonatomic, weak) MBProgressHUD *progressHUD;

@property (nonatomic, strong) SHLoginView *loginView;
@property (nonatomic, assign) BOOL hasLoad;

@property (nonatomic, weak) SHUserAccountInfoVC *userAccountInfoVC;
@property (nonatomic, strong) UIView *coverView;

@end

@implementation SHHomeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    SHLogTRACE();
    
    [self setupGUI];
//    [self loadData];
#if useAccountManager
//    [SHNetworkManager sharedNetworkManager].userLogin ? [self loadData] : void();
    [SHNetworkManager sharedNetworkManager].userLogin ? [self loadUserData] : void();
#endif
//    [self addSlideGesture];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:kLoginSuccessNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)login {
    if (_notRequiredLogin) {
        _notRequiredLogin = NO;
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserShouldLoginNotification object:nil];
    if (_userAccountInfoVC) {
        [_userAccountInfoVC dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)loginSuccess {
    [self loadUserData];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoginSuccessNotification object:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"needSyncDataFromServer"]) {
        [defaults setBool:NO forKey:@"needSyncDataFromServer"];
    }
}

- (void)setupGUI {
    [self.tableView registerNib:[UINib nibWithNibName:@"SHCameraViewCell" bundle:nil] forCellReuseIdentifier:kCameraViewCellID];
//    self.title = @"X-Sense";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-logo"]];
    
    self.tableView.rowHeight = [SHCameraViewModel rowHeight];
}

- (UIView *)coverView {
    if (_coverView == nil) {
        _coverView = [[UIView alloc] init];
        _coverView.frame = self.view.frame;
    }
    
    return _coverView;
}

- (void)loadUserData {
    SHLogTRACE();

    if (_notRequiredLogin) {
//        _notRequiredLogin = NO;
        return;
    }
    
    _hasLoad = YES;
//    [self getCameraList:^{
//        [self loadData];
//        _hasLoad = NO;
//    }];
    SHLogTRACE();
    [self loadData];

    WEAK_SELF(self);
//    [self.progressHUD showProgressHUDWithMessage:@"updating ..."/*NSLocalizedString(@"kLoading", nil)*/];
//    [self.view addSubview:self.coverView];
    [SHLocalWithRemoteHelper syncCameraList:^(BOOL isSuccess) {
        SHLogTRACE();

        if (isSuccess) {
            [weakself loadData];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakself.progressHUD hideProgressHUD:YES];
//            [weakself.coverView removeFromSuperview];
            weakself.hasLoad = NO;
            
            if (!isSuccess) {
//                [weakself showLoadCameraListFailedTips];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needSyncDataFromServer"];
            }
        });
    }];
}

- (void)showLoadCameraListFailedTips {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:/*@"Failed to get the camera list, please check if the network connection is normal."*/NSLocalizedString(@"kGetDeviceListFailed", nil) /*@"获取相机列表失败，请检测网络连接是否正常。"*/ preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)loadData {
    BOOL reload = [[NSUserDefaults standardUserDefaults] boolForKey:kNeedReloadDataBase];
    SHLogInfo(SHLogTagAPP, @"reload: %d", reload);
    
    if (reload || self.listViewModel.cameraList.count == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kNeedReloadDataBase];
        
        WEAK_SELF(self);
        [self.listViewModel loadCamerasWithCompletion:^{
            SHLogTRACE();

            STRONG_SELF(self);
            
            if (self) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
        }];
    } else {
        [self.tableView reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#if useAccountManager
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:kLoginSuccessNotification object:nil];
    [SHNetworkManager sharedNetworkManager].userLogin ? _hasLoad ? void() : [self syncDataFromServer] : [self login]/*[self.navigationController.view addSubview:self.loginView]*/;
#else
    [self loadData];
#endif
}

- (void)syncDataFromServer {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"needSyncDataFromServer"]) {
        [defaults setBool:NO forKey:@"needSyncDataFromServer"];
        [self loadUserData];
    } else {
        [self loadData];
    }
    
    if (_notRequiredLogin) {
        _notRequiredLogin = NO;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needSyncDataFromServer"];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoginSuccessNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addCameraAction:(id)sender {
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    SHSetupNavVC *navController = [sb instantiateViewControllerWithIdentifier:kSetupStoryboardID];
#if 0
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Setup" bundle:nil];
    SHSetupNavVC *navController = [sb instantiateInitialViewController];
    SHSetupHomeVC *vc = (SHSetupHomeVC *)navController.topViewController;
    vc.managedObjectContext = _managedObjectContext;
    
    [self.navigationController presentViewController:navController animated:YES completion:nil];
#endif
#if 0
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil];
    UINavigationController *nav = [sb instantiateInitialViewController];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
#endif
    
    [self scanQRCode];
}

- (void)scanQRCode {
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self presentQRCodeScanningVC];
                    
                    SGQRCodeLog(@"当前线程 - - %@", [NSThread currentThread]);
                    // 用户第一次同意了访问相机权限
                    SGQRCodeLog(@"用户第一次同意了访问相机权限");
                    
                } else {
                    
                    // 用户第一次拒绝了访问相机权限
                    SGQRCodeLog(@"用户第一次拒绝了访问相机权限");
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) { // 用户允许当前应用访问相机
            [self presentQRCodeScanningVC];
        } else if (status == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"kCameraAccessWarningInfo", @"") preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            NSLog(@"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kCameraNotDetected", @"") preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

- (void)presentQRCodeScanningVC {
    dispatch_async(dispatch_get_main_queue(), ^{
        SHQRCodeScanningVC *vc = [[SHQRCodeScanningVC alloc] init];
        SHSetupNavVC *nav = [[SHSetupNavVC alloc] initWithRootViewController:vc];
        
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listViewModel.cameraList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHCameraViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCameraViewCellID forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Configure the cell...
    cell.delegate = self;
    if (indexPath.row < self.listViewModel.cameraList.count) {
        cell.viewModel = self.listViewModel.cameraList[indexPath.row];
    }
    
    return cell;
}

#if 0
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    CGFloat space = 12;
//    CGFloat imageViewHeight = (UIScreen.screenWidth - 2 * space) * 9 / 16;
//    CGFloat footbarHeight = UIScreen.screenWidth * 5 / 34;
//    CGFloat rowHeight = kCameraTitleHeight + imageViewHeight + footbarHeight;
    
    SHCameraViewModel *viewModel = self.listViewModel.cameraList[indexPath.row];
    return viewModel.rowHeight;
}
#endif

- (void)connectCameraWithCameraObj:(SHCameraObject *)camObj {
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kConnecting", @"")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int retValue = [camObj connectCamera];
        
        if (retValue == ICH_SUCCEED) {
            [camObj initCamera];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                
                [self enterPreviewControllerWithCameraObj:camObj];
            });
        } else {
            NSString *name = camObj.camera.cameraName;
            NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
            NSString *errorInfo = @"";
            errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
            
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
            
            [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];

                [self presentViewController:alertC animated:YES completion:nil];
            });
        }
    });
}

- (void)enterPreviewControllerWithCameraObj:(SHCameraObject *)camObj {
    SHCameraPreviewVC *vc = [SHCameraPreviewVC cameraPreviewVC];
    vc.cameraUid = camObj.camera.cameraUid;
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - SHCameraViewCellDelegate
- (void)enterPreviewWithCell:(SHCameraViewCell *)cell {
    SHCameraObject *camObj = cell.viewModel.cameraObj;
    
#if 0
    if (camObj.isConnect) {
        [self enterPreviewControllerWithCameraObj:camObj];
    } else {
        [self connectCameraWithCameraObj:camObj];
    }
#else
    [self enterPreviewControllerWithCameraObj:camObj];
#endif
}

- (void)enterMessageCenterWithCell:(SHCameraViewCell *)cell {
#if 0
    UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:kMessageCenterStoryboardName bundle:nil];
    SHMsgCenterViewController *vc = [mainBoard instantiateViewControllerWithIdentifier:@"msgInfo"];
    vc.uuid = cell.viewModel.cameraObj.camera.cameraUid;
    [self.navigationController pushViewController:vc animated:YES];
#else
    UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:kMessageCenterStoryboardName bundle:nil];
    XJMessageCenterViewController *vc = [mainBoard instantiateViewControllerWithIdentifier:@"MessageCenter"];
    vc.camUid = cell.viewModel.cameraObj.camera.cameraUid;
    vc.title = @"Message Center";
    [self.navigationController pushViewController:vc animated:YES];
#endif
}

- (void)enterLocalAlbumWithCell:(SHCameraViewCell *)cell {
    // when (if = 0) for faster enter push test.
#if 1
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:kAlbumStoryboardName bundle:nil];
    SHLocalAlbumTVC *tvc = [mainStoryboard instantiateViewControllerWithIdentifier:@"LocalAlbumSBID"];
    tvc.cameraUid = cell.viewModel.cameraObj.camera.cameraUid;
    tvc.title = NSLocalizedString(@"kCameraRoll", nil); //@"Camera Roll";

    [self.navigationController pushViewController:tvc animated:YES];
#else
    SHPushTestNavController *nav = [SHPushTestNavController pushTestNavController];
    nav.title = cell.viewModel.cameraObj.camera.cameraUid;
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.isFullScreenPV = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:nav animated:YES completion:nil];
    });
#endif
}

- (void)enterShareWithCell:(SHCameraViewCell *)cell {
#if 0
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SHShareCameraViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ShareCameraStoryboardID"];
    vc.camera = cell.viewModel.cameraObj.camera;
    vc.title = @"Share";
    
    [self.navigationController pushViewController:vc animated:YES];
#endif
    
#if 0
    SHCameraObject *curSHCameraObj = cell.viewModel.cameraObj;
    if (curSHCameraObj.camera.operable) {
        SHShareHomeTVC *vc = [SHShareHomeTVC shareHomeViewController];
        vc.camera = curSHCameraObj.camera;
        vc.title = @"Share";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:vc animated:YES];
        });
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kNotShareCamera", @"") preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
#endif
    SHCameraObject *curSHCameraObj = cell.viewModel.cameraObj;
    if (curSHCameraObj.camera.operable == 1) {
        SHQRCodeShareVC *vc = [SHQRCodeShareVC qrCodeShareVC];
        vc.camera = curSHCameraObj.camera;
        vc.title = NSLocalizedString(@"kShare", nil); //@"Share";

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:vc animated:YES];
        });
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kNotShareCamera", @"") preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window ? self.view.window : self.navigationController.view];
    }
    
    return _progressHUD;
}

#pragma mark - init
- (SHCameraListViewModel *)listViewModel {
    if (_listViewModel == nil) {
        _listViewModel = [[SHCameraListViewModel alloc] init];
    }
    
    return _listViewModel;
}

#pragma mark - loginView
- (SHLoginView *)loginView {
    if (_loginView == nil) {
        _loginView = [SHLoginView loginView];
        _loginView.delegate = self;
        _loginView.yConstraint.constant = -30;
    }
    
    return _loginView;
}

- (void)logonAccount:(SHLoginView *)loginView {
    SHLogonViewController *vc = [SHLogonViewController logonViewController];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:vc animated:YES];
        [self.loginView removeFromSuperview];
    });
}

- (void)loginAccount:(SHLoginView *)loginView {
    [self.loginView.emailTextField resignFirstResponder];
    [self.loginView.pwdTextField resignFirstResponder];
    __block NSRange emailRange;
    __block NSRange passwordRange;
    
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:@"正在登录..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            emailRange = [self.loginView.emailTextField.text rangeOfString:@"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}" options:NSRegularExpressionSearch];
            passwordRange = [self.loginView.pwdTextField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,16}" options:NSRegularExpressionSearch];
        });
        
        if (emailRange.location == NSNotFound || passwordRange.location == NSNotFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"输入的邮箱或密码无效，请重新输入" preferredStyle:UIAlertControllerStyleAlert];
                [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertC animated:YES completion:nil];
            });
        } else {
            __block NSString *email = nil;
            __block NSString *password = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                email = self.loginView.emailTextField.text;
                password = self.loginView.pwdTextField.text;
            });
            
            WEAK_SELF(self);
            [[SHNetworkManager sharedNetworkManager] loadAccessTokenByEmail:email password:password completion:^(BOOL isSuccess, id result) {
                SHLogInfo(SHLogTagAPP, @"load accessToken is success: %d", isSuccess);
                
                if (isSuccess) {
                    [weakself getCameraList:^{
                        [weakself loadData];
                    }];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (isSuccess) {
                        [weakself.progressHUD hideProgressHUD:YES];

                        [weakself closeLoginView];
                    } else {
                        Error *error = result;
                        
                        weakself.progressHUD.detailsLabelText = error.error_description;
                        NSString *notice = @"登录失败";
                        [weakself.progressHUD showProgressHUDNotice:notice showTime:1.5];
                    }
                });
            }];
        }
    });
}

- (void)closeLoginView {
    [self.loginView removeFromSuperview];
    _loginView = nil;
}

- (void)getCameraList:(void (^)())completion {
    WEAK_SELF(self);
    
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLoading", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SHNetworkManager sharedNetworkManager] getCameraList:^(BOOL isSuccess, id result) {
            SHLogInfo(SHLogTagAPP, @"get camera list is success: %d", isSuccess);
            
            if (isSuccess) {
                [[CoreDataHandler sharedCoreDataHander] deleteAllCameras];
                
                [weakself addCameras2LocalSqlite:result andResultDeal:completion];
                
//                if (completion) {
//                    completion();
//                }
//
//                [weakself unbindCameras:result];
            } else {
                Error *error = result;
                NSLog(@"getCameraList is faild: %@", error.error_description);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _progressHUD = nil;
            });
        }];
    });
}

- (void)addCameras2LocalSqlite:(NSArray *)cameraList andResultDeal:(void (^)())completion {
    if(cameraList.count) {
        NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
        
        [cameraList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Camera *info = obj;
            if([info.ownerId compare:owner] == 0) {
                [self addCamera2LocalSqlite:info];
                if(completion) {
                    completion();
                }
            } else {
                [[SHNetworkManager sharedNetworkManager] getCameraByCameraID:info.id completion:^(BOOL isSuccess, id  _Nonnull result) {
                    if(isSuccess) {
                        [self addCamera2LocalSqlite:result];
                        if(completion) {
                            completion();
                        }
                    }
                }];
            }
        }];

    } else {
        if(completion) {
            completion();
        }
    }
    
}

- (void)addCamera2LocalSqlite:(Camera *)camera_server {
#if USE_ENCRYP
    NSString *token = camera_server.uid;
    NSString *uidToken = [[SHQRManager sharedQRManager] getUIDToken:token];
    NSString *uid = [[SHQRManager sharedQRManager] getUID:token];
    
    if (token == nil || uidToken == nil || uid == nil) {
//            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:[self tipsInfoFromParseResult:parseResult] preferredStyle:UIAlertControllerStyleAlert];
//            [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self.progressHUD hideProgressHUD:YES];
//                    //                        [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
//                    [self.navigationController popViewControllerAnimated:YES];
//                });
//            }]];
//    
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self presentViewController:alertVC animated:YES completion:nil];
//            });
        SHLogError(SHLogTagAPP, @"token or uidToken or uid is nil.");
        
        return;
    }
    
    SHCameraHelper *camera = [SHCameraHelper cameraWithName:camera_server.name cameraToken:token cameraUidToken:uidToken devicePassword:camera_server.devicepassword id:camera_server.id operable:camera_server.operable];
#else
    NSString *urlStr = [NSString stringWithFormat:@"%@", camera_server.cover];
    NSURL *url= [NSURL URLWithString:urlStr];
    NSData *imgData = [NSData dataWithContentsOfURL:url];
    UIImage *thumbnail = nil;
    if(imgData.length > 0) {
        thumbnail =  [UIImage imageWithData:imgData];
    }
    int permission = -1;
    NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
    if([camera_server.ownerId compare:owner] != 0) {
        permission = camera_server.operable;
    }
    NSLog(@"own camera : %@ operable = %d", permission == -1 ? @"YES" : @"NO", permission);
    NSString *name = camera_server.name;
    if(permission != -1 ) {
        name = camera_server.memoname;
    }
    SHCameraHelper *camera = [SHCameraHelper cameraWithName:name cameraUid:camera_server.uid devicePassword:camera_server.devicepassword id:camera_server.id thumbnail:thumbnail operable:permission];
#endif
    SHLogInfo(SHLogTagAPP, @"===> camera: %@", camera);
    
    [[CoreDataHandler sharedCoreDataHander] addCamera:camera];
}

- (IBAction)enterUserAccountInfoAction:(id)sender {
#if 0
    SHUserAccountInfoTVC *vc = [SHUserAccountInfoTVC userAccountInfoTVC];
    vc.managedObjectContext = _managedObjectContext;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:vc animated:YES];
    });
#else
//    [self enterUserAccountInfoView];
    
    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] openLeftMenu];
#endif
}

- (void)enterUserAccountInfoView {
//    SHUserAccountInfoTVC *vc = [SHUserAccountInfoTVC userAccountInfoTVC];
//    vc.managedObjectContext = _managedObjectContext;
    SHUserAccountInfoVC *vc = [[SHUserAccountInfoVC alloc] init];
    vc.managedObjectContext = _managedObjectContext;
    
    [self cw_showDefaultDrawerViewController:vc];
//    [self.navigationController pushViewController:vc animated:YES];
    self.userAccountInfoVC = vc;
}

- (IBAction)enterUserAccountMessageCenter:(id)sender {
#if 0
    SHMessagesListTVC *vc = [SHMessagesListTVC messageListTVC];
    vc.managedObjectContext = _managedObjectContext;
    vc.title = @"UserAccountMessageCenter";
    
    [self.navigationController pushViewController:vc animated:YES];
#endif
    
    [self addCameraAction:nil];
}

#pragma mark - LaterSlide
- (void)addSlideGesture {
    WEAK_SELF(self);
    [self cw_registerShowIntractiveWithEdgeGesture:NO transitionDirectionAutoBlock:^(CWDrawerTransitionDirection direction) {
        if (direction == CWDrawerTransitionFromLeft) {
            [weakself enterUserAccountInfoView];
        }
    }];
}

- (void)longPressDeleteCamera:(SHCameraViewCell *)cell {
    SHCameraObject *camObj = cell.viewModel.cameraObj;
    
    if (camObj) {
        [self showDeleteCameraAlertWithIndexPath:nil camObj:camObj];
    }
}

- (void)showDeleteCameraAlertWithIndexPath:(NSIndexPath *)indexPath camObj:(SHCameraObject *)camObj {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Are you sure you want to remove this record", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        STRONG_SELF(self);
        
        [self deleteCameraWithCamObj:camObj completion:^{
            [self loadData];
        }];
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)deleteCameraWithCamObj:(SHCameraObject *)shCamObj completion:(void (^)())completion {
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#ifdef USE_SYNC_REQUEST_PUSH
        if (![SHTutkHttp unregisterDevice:shCamObj.camera.cameraUid]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                [self showDeleteCameraFailedInfo];
            });
            return;
        }
        
        if (shCamObj.camera.operable == 1) {
            [self unbindCameraWithCamObj:shCamObj completion:completion];
        } else {
            [self unsubscribeCameraWithCamObj:shCamObj completion:completion];
        }
#else
        WEAK_SELF(self);
        [SHTutkHttp unregisterDevice:shCamObj.camera.cameraUid completionHandler:^(BOOL isSuccess) {
            if (isSuccess == NO) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                    [weakself showDeleteCameraFailedInfo];
                });
            } else {
                if (shCamObj.camera.operable == 1) {
                    [weakself unbindCameraWithCamObj:shCamObj completion:completion];
                } else {
                    [weakself unsubscribeCameraWithCamObj:shCamObj completion:completion];
                }
            }
        }];
#endif
    });
}

- (void)showDeleteCameraFailedInfo {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kUnregisterDeviceFailed", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)deleteCameraDetailWithCamObj:(SHCameraObject *)shCamObj completion:(void (^)())completion {
    NSString *message = NSLocalizedString(@"Deleted", nil);
    
//    NSString *cameraUid = shCamObj.camera.cameraUid;
    if ([[CoreDataHandler sharedCoreDataHander] deleteCamera:shCamObj.camera]) {
        shCamObj.cameraProperty.fwUpdate = NO;
        if (shCamObj.isConnect) {
            [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
        }
        
        //清除相机的push msg信息及缓存的视频缩略图
//        MessageCenter *msgCenter = [MessageCenter MessageCenterWithName:shCamObj.camera.cameraUid andMsgDelegate:nil];
//        [msgCenter clearAllMessage];
        
//        [[XJLocalAssetHelper sharedLocalAssetHelper] deleteLocalAllAssetsWithKey:cameraUid completionHandler:^(BOOL success) {
//            SHLogInfo(SHLogTagAPP, @"Delete local all asset is success: %d", success);
//        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    } else {
        message = NSLocalizedString(@"DeleteError", nil);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD showProgressHUDNotice:message showTime:2.0];
    });
}

- (void)unbindCameraWithCamObj:(SHCameraObject *)shCamObj completion:(void (^)())completion {
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] unbindCameraWithCameraID:shCamObj.camera.id completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"unbind camera is success: %d", isSuccess);
        
        if (isSuccess) {
            [weakself deleteCameraDetailWithCamObj:shCamObj completion:completion];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
                
                Error *error = result;
                [weakself showFailedTipsWithInfo:[NSString stringWithFormat:/*@"解除账户相机绑定失败. \n%@"*/@"%@ \n%@", NSLocalizedString(@"kUnbindDeviceFailed", nil), /*error.error_description*/[SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code]]];
            });
        }
    }];
}

- (void)unsubscribeCameraWithCamObj:(SHCameraObject *)shCamObj completion:(void (^)())completion {
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] unsubscribeCameraWithCameraID:shCamObj.camera.id completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"unsubscribe camera is success: %d", isSuccess);
        
        if (isSuccess) {
            [weakself deleteCameraDetailWithCamObj:shCamObj completion:completion];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
                
                Error *error = result;
                [weakself showFailedTipsWithInfo:[NSString stringWithFormat:/*@"取消订阅失败. \n%@"*/@"%@ \n%@", NSLocalizedString(@"kUnsubscribeFailed", nil), /*error.error_description*/[SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code]]];
            });
        }
    }];
}

- (void)showFailedTipsWithInfo:(NSString *)info {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:info/*NSLocalizedString(@"kUnregisterDeviceFailed", nil)*/ preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertC dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

@end
