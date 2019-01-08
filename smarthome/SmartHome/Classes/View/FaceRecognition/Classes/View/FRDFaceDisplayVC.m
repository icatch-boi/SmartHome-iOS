//
//  FRDFaceShowViewController.m
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "FRDFaceDisplayVC.h"
#import "SHNetworkManager+SHFaceHandle.h"
#import "SVProgressHUD.h"
#import "FRDFaceDetectionVC.h"
#import "FRDCommonHeader.h"
#import "FRDFaceInfo.h"
#import "UIImageView+WebCache.h"
#import "FRDFaceInfo.h"
#import "FRDFaceInfoViewModel.h"

@interface FRDFaceDisplayVC ()

@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;

@end

@implementation FRDFaceDisplayVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFaceInfo:) name:kUpdateFacesInfoNotification object:nil];
}

- (void)setupGUI {
    self.title = self.faceInfo.name;
    
    [self displayPicture];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)displayPicture {
    NSURL *url = [NSURL URLWithString:self.faceInfo.url];
//    NSLog(@"urlString: %@", self.faceInfo.url);
    
    self.faceImageView.image = nil;
    
    [SVProgressHUD show];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    
    WEAK_SELF(self);
    [self.faceImageView sd_setImageWithURL:url completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        NSLog(@"get image: %@", image);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (image == nil) {
                [weakself getImageFailedHandler];
            }
        });
    }];
}

- (void)getImageFailedHandler {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Tips" message:@"Get face image failed, please try again." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self displayPicture];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)updateFaceInfo:(NSNotification *)notication {
    [self updateFaceInfoHandler];
}

- (void)updateFaceInfoHandler {
#if 0
    [SVProgressHUD show];
    
    WEAKSELF(self);
    [[ZJNetworkManager sharedNetworkManager] getFacesInfoWithName:self.faceInfo.name finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (error != nil) {
                [SVProgressHUD showErrorWithStatus:error.error_description];
                [SVProgressHUD dismissWithDelay:2.0];
            } else {
//                weakself.faceInfo = [FRDFaceInfo faceInfoWithDict:result];
                NSLog(@"result: %@", result);

                [weakself displayPicture];
            }
        });
    }];
    
#else
    
    WEAK_SELF(self);
    [self.faceInfoViewModel loadFacesInfoWithCompletion:^{
        [weakself.faceInfoViewModel.facesInfoArray enumerateObjectsUsingBlock:^(FRDFaceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:weakself.faceInfo.name]) {
                weakself.faceInfo = obj;
                
                *stop = YES;
            }
        }];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kReloadFlag];
        
        [NSThread sleepForTimeInterval:1.0];
        [weakself displayPicture];
    }];
#endif
}

- (IBAction)moreClick:(id)sender {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Tips" message:@"There are more operation" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self resetHandler];
    }]];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self sureDeleteFacePictureTips];
    }]];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        alertVC.popoverPresentationController.sourceView = self.view;
        alertVC.popoverPresentationController.sourceRect = CGRectMake(self.view.center.x, self.view.center.y, 1.0, 1.0);
    }
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)resetHandler {
    [self performSegueWithIdentifier:@"resetFacePictureSegue" sender:nil];
}

- (void)sureDeleteFacePictureTips {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Tips" message:@"Confirm to delete the face picture ?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self deleteHandler];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)deleteHandler {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] deleteFacePictureWithName:self.faceInfo.name finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        [SVProgressHUD dismiss];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [SVProgressHUD showErrorWithStatus:error.error];
                [SVProgressHUD dismissWithDelay:2.0];
            } else {
                [weakself.navigationController popViewControllerAnimated:YES];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kReloadFacesInfoNotification object:nil];
            }
        });
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"resetFacePictureSegue"]) {
        FRDFaceDetectionVC *vc = segue.destinationViewController;
        
        vc.userName = self.faceInfo.name;
        vc.reset = YES;
    }
}

@end
