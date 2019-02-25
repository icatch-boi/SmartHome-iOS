//
//  FRDFacesViewController.m
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "FRDFacesViewController.h"
#import "SHNetworkManager+SHFaceHandle.h"
#import "SVProgressHUD.h"
#import "FRDFaceDisplayVC.h"
#import "FRDCommonHeader.h"
#import "FRDFaceInfo.h"
#import "FRDFaceInfoViewModel.h"

static NSString * const ReuseIdentifier = @"faceCellID";

@interface FRDFacesViewController ()

@property (nonatomic, strong) FRDFaceInfoViewModel *faceInfoViewModel;

@end

@implementation FRDFacesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadFacesInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFacesInfoHandler:) name:kReloadFacesInfoNotification object:nil];
    [self setupLocalizedString];
}

- (void)setupLocalizedString {
    self.title = NSLocalizedString(@"kFaceDatabase", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self loadFacesInfo];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kReloadFlag]) {
        [defaults setBool:NO forKey:kReloadFlag];
        
        [self.tableView reloadData];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadFacesInfoHandler:(NSNotification *)notification {
    [self loadFacesInfo];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.faceInfoViewModel.facesInfoArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = self.faceInfoViewModel.facesInfoArray[indexPath.row].name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:@"go2DisplayVCSegue" sender:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *faceName = self.faceInfoViewModel.facesInfoArray[indexPath.row].name;
        faceName != nil ? [self showDeleteFacePictureTipsWithFaceName:faceName] : void();
    }
}

- (void)showDeleteFacePictureTipsWithFaceName:(NSString *)faceName {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kConfirmDeleteFacePictureDes", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        STRONG_SELF(self);
        [self deleteHandlerWithFaceName:faceName];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)deleteHandlerWithFaceName:(NSString *)faceName {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];
    
    [[SHNetworkManager sharedNetworkManager] deleteFacePictureWithName:faceName finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        [SVProgressHUD dismiss];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [SVProgressHUD showErrorWithStatus:error.error];
                [SVProgressHUD dismissWithDelay:2.0];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kReloadFacesInfoNotification object:nil];
            }
        });
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = sender;
    
    if ([segue.identifier isEqualToString:@"go2DisplayVCSegue"]) {
        FRDFaceDisplayVC *vc = segue.destinationViewController;
        
        vc.faceInfo = self.faceInfoViewModel.facesInfoArray[indexPath.row];
        vc.faceInfoViewModel = self.faceInfoViewModel;
    }
}

#pragma mark - Load Data
- (void)loadFacesInfo {
    WEAK_SELF(self);
    [self.faceInfoViewModel loadFacesInfoWithCompletion:^{        
        [weakself.tableView reloadData];
    }];
}

- (void)saveFacesInfoToLocal:(NSArray *)faces {
    [[NSUserDefaults standardUserDefaults] setObject:faces forKey:kLocalFacesInfo];
}

- (FRDFaceInfoViewModel *)faceInfoViewModel {
    if (_faceInfoViewModel == nil) {
        _faceInfoViewModel = [[FRDFaceInfoViewModel alloc] init];
    }
    
    return _faceInfoViewModel;
}

@end
