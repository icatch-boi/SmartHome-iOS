// SHStrangerViewController.m

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
 
 // Created by zj on 2019/8/5 6:28 PM.
    

#import "SHStrangerViewController.h"
#import "SHNetworkManager+SHFaceHandle.h"
#import "SVProgressHUD.h"
#import "SHFaceDataManager.h"
#import "FRDCommonHeader.h"
#import "FaceCollectCommon.h"

@interface SHStrangerViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UIButton *addFaceButton;

@property (nonatomic, strong) UIImage *faceImage;
@property (nonatomic, copy) NSString *faceName;
@property (nonatomic, copy) NSString *faceid;
@property (nonatomic, strong) dispatch_group_t addFaceGroup;
@property (nonatomic, strong) dispatch_queue_t addFaceQueue;
@property (nonatomic, assign) BOOL uploadSuccess;
@property (nonatomic, assign) BOOL setupSuccess;

@end

@implementation SHStrangerViewController

+ (instancetype)strangerViewControllerWithFaceImage:(UIImage *)image {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kFaceCollect bundle:nil];
    SHStrangerViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    vc.faceImage = image;
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupFaceImage];
    [self setupLocalizedString];
}

- (void)setupLocalizedString {
    self.title = NSLocalizedString(@"kAddFaces", nil);
    
    [self.addFaceButton setTitle:NSLocalizedString(@"kAddFaces", nil) forState:UIControlStateNormal];
    [self.addFaceButton setTitle:NSLocalizedString(@"kAddFaces", nil) forState:UIControlStateHighlighted];
}

- (void)setupFaceImage {
    self.faceImageView.image = self.faceImage;
}

- (IBAction)addFaceClick:(id)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"kGetFaceID", nil)];
    
    WEAK_SELF(self);
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        [[SHNetworkManager sharedNetworkManager] getAvailableFaceid:^(id  _Nullable result, ZJRequestError * _Nullable error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [SVProgressHUD dismiss];
                
                STRONG_SELF(self);
                if (error != nil) {
                    SHLogError(SHLogTagAPP, @"getAvailableFaceid failed, error: %@", error);
                    
                    [self showUploadFailedAlertView:[NSString stringWithFormat:NSLocalizedString(@"kGetFaceIDFailed", nil), error.error_description]];
                } else {
                    SHLogInfo(SHLogTagAPP, @"result: %@", result);
                    NSString *faceid = [result[@"faceid"] stringValue];
                    if (faceid == nil) {
                        [self showUploadFailedAlertView:NSLocalizedString(@"kFaceIDEmpty", nil)];
                    } else {
                        self.faceid = faceid;
                        [self showAddFacesAlertView];
                    }
                }
            }];
        }];
    }];
}

- (void)showUploadFailedAlertView:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Add Faces Handler
- (void)showAddFacesAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kSetupFaceName", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *nameTextField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        
        nameTextField = textField;
    }];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kUploadFacePicture", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = nameTextField.text;
        
        STRONG_SELF(self);
        if (name == nil || [name isEqualToString:@""]) {
            [self inputEmptyAlert];
        } else {
            if ([self hasFaceInfoWithName:name]) {
                [self alreadyExistFaceInfoAlert:name];
            } else {
                [self uploadHandlerWithName:name];
            }
        }
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)uploadHandlerWithName:(NSString *)name {
    self.faceName = name;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"kAddingFaceData", nil)];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    self.uploadSuccess = false;
    self.setupSuccess = false;
    
    dispatch_group_enter(self.addFaceGroup);
    dispatch_async(self.addFaceQueue, ^{
        [self uploadFaceDataWithName:name];
    });
    
    dispatch_group_enter(self.addFaceGroup);
    dispatch_async(self.addFaceQueue, ^{
        [self setupFaceDataToFW];
    });
    
    dispatch_group_notify(self.addFaceGroup, dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        
        if (self.uploadSuccess == true && self.setupSuccess == true) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"kAddFacePictureSuccess", nil), self.faceName]];
            [SVProgressHUD dismissWithDelay:2.0];
            
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            SHLogError(SHLogTagAPP, @"addFaceData failed, uploadSuccess: %d, setupSuccess: %d", self.uploadSuccess, self.setupSuccess);
            
            NSString *notice = NSLocalizedString(@"kAddFaceDataFailed", nil);
            if (self.setupSuccess == true) {
                notice = NSLocalizedString(@"kUploadFaceDataFailed", nil);
                
                [[SHFaceDataManager sharedFaceDataManager] deleteFacesWithFaceIDs:@[self.faceid]];
            } else if (self.uploadSuccess == true) {
                notice = NSLocalizedString(@"kAddFaceDataToFWFailed", nil);
                
                [self uploadFaceDataFailedHandle];
            }
            
            [self showUploadFailedAlertView:notice];
        }
    });
}

- (void)setupFaceDataToFW {
    NSMutableArray *temp = [NSMutableArray array];
    
    int totalSize = 0;
    UIImage *img = [self compressImage:self.faceImage];
    if (img != nil) {
        NSData *data = UIImageJPEGRepresentation(img, 1.0);
        totalSize += data.length;
        [temp addObject:data];
    }
    
    if (temp.count <= 0) {
        SHLogError(SHLogTagAPP, @"Face DataSet is nil.");
        dispatch_async(dispatch_get_main_queue(), ^{

            [self showUploadFailedAlertView:NSLocalizedString(@"kFaceDataSetNotExist", nil)];
            [self uploadFaceDataFailedHandle];
        });
        
        dispatch_group_leave(self.addFaceGroup);
        return;
    }
    
    SHLogInfo(SHLogTagAPP, @"Face data set length: %d", totalSize);
    
    [[SHFaceDataManager sharedFaceDataManager] addFaceDataWithFaceID:self.faceid faceData:temp.copy completion:^(BOOL isSuccess) {

        self.setupSuccess = isSuccess;
        dispatch_group_leave(self.addFaceGroup);
    }];
}

- (void)uploadFaceDataWithName:(NSString *)name {
    UIImage *img = self.faceImage;
    if (img == nil) {
        SHLogError(SHLogTagAPP, @"Main face is nil.");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showUploadFailedAlertView:NSLocalizedString(@"kFaceDataNotExist", nil)];
        });
        
        dispatch_group_leave(self.addFaceGroup);
        return;
    }
    
    NSData *data = UIImageJPEGRepresentation(img, 1.0);
    [[SHNetworkManager sharedNetworkManager] uploadFaceData:data faceid:self.faceid name:name finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        if (error != nil) {
            SHLogError(SHLogTagAPP, @"uploadFaceData failed, error: %@", error.error_description);
            dispatch_async(dispatch_get_main_queue(), ^{

                [self showUploadFailedAlertView:[NSString stringWithFormat:NSLocalizedString(@"kUploadFaceDataFailedDes", nil), error.error_description]];
            });
            dispatch_group_leave(self.addFaceGroup);
        } else {
            [self uploadFaceDataSetWithName:name];
        }
    }];
}

- (void)uploadFaceDataSetWithName:(NSString *)name {
    NSMutableDictionary *temp = [NSMutableDictionary dictionary];
    
    UIImage *img = [self compressImage:self.faceImage];
    if (img != nil) {
        NSData *data = UIImageJPEGRepresentation(img, 1.0);
        temp[@"bestImage"] = [data base64EncodedStringWithOptions:0];
    }
    
    if (temp.count <= 0) {
        SHLogError(SHLogTagAPP, @"Face DataSet is nil.");
        dispatch_async(dispatch_get_main_queue(), ^{

            [self showUploadFailedAlertView:NSLocalizedString(@"kFaceDataSetNotExist", nil)];
            [self uploadFaceDataFailedHandle];
        });
        
        dispatch_group_leave(self.addFaceGroup);
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:temp options:0 error:nullptr];
    SHLogInfo(SHLogTagAPP, @"data length: %d", data.length);
    
    [[SHNetworkManager sharedNetworkManager] uploadFaceDataSet:data faceid:self.faceid finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {

        if (error != nil) {
            SHLogError(SHLogTagAPP, @"uploadFaceDataSet failed, error: %@", error.error_description);
            
            dispatch_async(dispatch_get_main_queue(), ^{

                [self showUploadFailedAlertView:[NSString stringWithFormat:NSLocalizedString(@"kUplaodFaceDataSetFailedDes", nil), error.error_description]];
            });
            
            [self uploadFaceDataFailedHandle];
        } else {
            self.uploadSuccess = true;
        }
        
        dispatch_group_leave(self.addFaceGroup);
    }];
}

- (void)uploadFaceDataFailedHandle {
    SHLogTRACE();
    [[SHNetworkManager sharedNetworkManager] deleteFaceDataWithFaceid:self.faceid finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [SVProgressHUD showErrorWithStatus:error.error];
                [SVProgressHUD dismissWithDelay:2.0];
            }
        });
    }];
}

- (void)alreadyExistFaceInfoAlert:(NSString *)name {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:[NSString stringWithFormat:NSLocalizedString(@"kFaceAlreadyExist", nil), name] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddFacesAlertView];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (BOOL)hasFaceInfoWithName:(NSString *)name {
    __block BOOL has = false;
    NSArray *localFaces = [[NSUserDefaults standardUserDefaults] objectForKey:kLocalFacesInfo];
    
    if (localFaces && localFaces.count > 0) {
        [localFaces enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj[@"name"] isEqualToString:name]) {
                has = true;
                *stop = true;
            }
        }];
    }
    
    return has;
}

- (void)inputEmptyAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"kFaceNameInvalid", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddFacesAlertView];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (UIImage *)compressImage:(UIImage *)image {
    CGSize size = CGSizeMake(kCompressImageWidth, kCompressImageWidth);
    
    UIGraphicsBeginImageContext(size);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Init
- (dispatch_group_t)addFaceGroup {
    if (_addFaceGroup == nil) {
        _addFaceGroup = dispatch_group_create();
    }
    
    return _addFaceGroup;
}

- (dispatch_queue_t)addFaceQueue {
    if (_addFaceQueue == nil) {
        _addFaceQueue = dispatch_queue_create("com.icatchtek.AddFace", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return _addFaceQueue;
}

@end
