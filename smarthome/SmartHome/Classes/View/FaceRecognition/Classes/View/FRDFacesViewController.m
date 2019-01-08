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

//@property (nonatomic, strong) NSArray<FRDFaceInfo *> *facesArray;
@property (nonatomic, strong) FRDFaceInfoViewModel *faceInfoViewModel;

@end

@implementation FRDFacesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadFacesInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFacesInfoHandler:) name:kReloadFacesInfoNotification object:nil];
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
#if 0
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];
    
    WEAKSELF(self);
    [[ZJNetworkManager sharedNetworkManager] getFacesInfoWithName:nil finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (error) {
                [SVProgressHUD showErrorWithStatus:error.error];
                [SVProgressHUD dismissWithDelay:2.0];
            } else {
                NSArray *faceInfoArray = (NSArray *)result;
                
                NSMutableArray *faceInfoModelMArray = [NSMutableArray arrayWithCapacity:faceInfoArray.count];
                [faceInfoArray enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    FRDFaceInfo *faceInfo = [FRDFaceInfo faceInfoWithDict:obj];
                    [faceInfoModelMArray addObject:faceInfo];
                }];
                
                weakself.facesArray = faceInfoModelMArray.copy;
                
                [weakself.tableView reloadData];
                
                [weakself saveFacesInfoToLocal:result];
            }
        });
    }];
    
#else
    
    WEAK_SELF(self);
    [self.faceInfoViewModel loadFacesInfoWithCompletion:^{        
        [weakself.tableView reloadData];
    }];
#endif
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
