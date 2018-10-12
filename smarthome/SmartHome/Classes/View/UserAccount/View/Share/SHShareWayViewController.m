//
//  SHShareWayVC.m
//  SmartHome
//
//  Created by ZJ on 2018/3/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHShareWayViewController.h"
#import "SHQRCodeShareVC.h"
#import "SHShareOtherAccountVC.h"

@interface SHShareWayViewController ()

@end

@implementation SHShareWayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2QRCodeShareVCID"]) {
        SHQRCodeShareVC *vc = segue.destinationViewController;
        vc.camera = _camera;
    } else if ([segue.identifier isEqualToString:@"go2ShareOtherAccountVCID"]) {
        SHShareOtherAccountVC *vc = segue.destinationViewController;
        vc.camera = _camera;
    }
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
