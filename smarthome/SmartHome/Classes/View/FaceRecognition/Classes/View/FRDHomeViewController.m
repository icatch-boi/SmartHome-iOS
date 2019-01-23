//
//  FRDHomeViewController.m
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "FRDHomeViewController.h"
#import "FRDFaceDetectionVC.h"

@interface FRDHomeViewController ()

@end

@implementation FRDHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setupGUI];
}

- (void)setupGUI {
    [SHTool configureAppThemeWithController:self.navigationController];
    [self setupCloseButton];
}

- (void)setupCloseButton {
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:self action:@selector(closeCurrentVC) isBack:NO];
    self.navigationItem.leftBarButtonItem = closeBtn;
}

- (void)closeCurrentVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#if DEBUG
    return 2;
#else
    return 1;
#endif
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1) {
        [self performSegueWithIdentifier:@"faceRecognitionSegue" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"faceRecognitionSegue"]) {
        FRDFaceDetectionVC *vc = segue.destinationViewController;
        
        vc.recognition = YES;
    }
}

@end
