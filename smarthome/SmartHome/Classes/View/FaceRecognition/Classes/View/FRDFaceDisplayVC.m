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
#import "SHFaceDataManager.h"

@interface FRDFaceDisplayVC ()

@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButtonItem;

@end

@implementation FRDFaceDisplayVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFaceInfo:) name:kUpdateFacesInfoNotification object:nil];
    [self setupLocalizedString];
}

- (void)setupLocalizedString {
    self.moreButtonItem.title = NSLocalizedString(@"kMore", nil);
}

- (void)setupGUI {
    self.title = self.faceInfo.name;
    self.faceImageView.backgroundColor = self.view.backgroundColor;
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFit;
    
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
#if 0
    if (self.faceInfo.faceImage != nil) {
        self.faceImageView.image = self.faceInfo.faceImage;
        return;
    }
    NSURL *url = [NSURL URLWithString:self.faceInfo.url];
//    NSLog(@"urlString: %@", self.faceInfo.url);
    
    self.faceImageView.image = nil;
    
    [SVProgressHUD show];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    
    WEAK_SELF(self);
    [self.faceImageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"portrait"] options:SDWebImageRefreshCached completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        NSLog(@"get image: %@", image);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (image == nil) {
                [weakself getImageFailedHandler];
            } else {
                self.faceInfo.faceImage = image;
            }
        });
    }];
#else
    self.faceImageView.image = [UIImage imageNamed:@"portrait"];
    
    [SVProgressHUD show];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    
    WEAK_SELF(self);
    [self.faceInfo getFaceImageWithCompletion:^(UIImage * _Nullable faceImage) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];

            if (faceImage == nil) {
                [weakself getImageFailedHandler];
            } else {
                self.faceImageView.image = faceImage;
            }
        });
    }];
#endif
}

- (void)getImageFailedHandler {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kGetFaceImgaeFailedDescription", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self displayPicture];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)updateFaceInfo:(NSNotification *)notication {
    [self updateFaceInfoHandler];
}

- (void)updateFaceInfoHandler {
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
}

- (IBAction)moreClick:(id)sender {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kMoreOperationDescription", nil) preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    
//    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kReset", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [self resetHandler];
//    }]];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
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
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kConfirmDeleteFacePictureDes", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self deleteHandler];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)deleteHandler {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];
    
    WEAK_SELF(self);
#if 0
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
#else
    [[SHNetworkManager sharedNetworkManager] deleteFaceDataWithFaceid:self.faceInfo.faceid finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        [SVProgressHUD dismiss];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [SVProgressHUD showErrorWithStatus:error.error];
                [SVProgressHUD dismissWithDelay:2.0];
            } else {
                [weakself.navigationController popViewControllerAnimated:YES];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kReloadFacesInfoNotification object:nil];
                [[SHFaceDataManager sharedFaceDataManager] deleteFacesWithFaceIDs:@[self.faceInfo.faceid]];
            }
        });
    }];
#endif
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"resetFacePictureSegue"]) {
        FRDFaceDetectionVC *vc = segue.destinationViewController;
        
        vc.userName = self.faceInfo.name;
        vc.reset = YES;
    }
}

@end
