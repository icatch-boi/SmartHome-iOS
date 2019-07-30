//
//  DisplayViewController.m
//  FaceSDK-Collect-WithLiveness-iOS
//
//  Created by ZJ on 2019/7/10.
//  Copyright © 2019 Baidu. All rights reserved.
//

#import "DisplayViewController.h"
#import "SHNetworkManager+SHFaceHandle.h"
#import "SVProgressHUD.h"
#import "FRDCommonHeader.h"
#import "SHFaceDataManager.h"

static const CGFloat kImageWHScale = 684.0 / 512; //716.0 / 512;
static const CGFloat kUploadImageWidth = 224;
static const CGFloat kMarginTop = 140;

@interface DisplayViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *mainFaceImgView;
@property (weak, nonatomic) IBOutlet UIImageView *yawLeftImgView;
@property (weak, nonatomic) IBOutlet UIImageView *yawRightImgView;
@property (weak, nonatomic) IBOutlet UIImageView *pitchUpImgView;
@property (weak, nonatomic) IBOutlet UIImageView *pitchDownImgView;
@property (weak, nonatomic) IBOutlet UIButton *addFaceButton;

@property (nonatomic, strong) NSMutableDictionary *faceImages;
@property (nonatomic, copy) NSString *faceid;
@property (nonatomic, assign) BOOL collectFailed;

@end

@implementation DisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self updateImages:self.images];
    [self setupGUI];
}

- (void)setupGUI {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-back"] style:UIBarButtonItemStyleDone target:self action:@selector(returnBackClick:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-cancel"] style:UIBarButtonItemStyleDone target:self action:@selector(exitFaceCollect)];
    self.addFaceButton.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = false;
}

- (void)updateImages:(NSDictionary *)images {
//    if (images[@"bestImage"] != nil) {
//        NSLog(@"-- bestImage: %@", images[@"bestImage"]);
//        self.mainFaceImgView.image = [self recognitionFaces:images[@"bestImage"]];
//    }
//
//    if (images[@"yawRight"] != nil) {
//        self.yawRightImgView.image = [self recognitionFaces:images[@"yawRight"]];
//    }
//
//    if (images[@"yawLeft"] != nil) {
//        self.yawLeftImgView.image = [self recognitionFaces:images[@"yawLeft"]];
//    }
//
//    if (images[@"pitchUp"] != nil) {
//        self.pitchUpImgView.image = [self recognitionFaces:images[@"pitchUp"]];
//    }
//
//    if (images[@"pitchDown"] != nil) {
//        self.pitchDownImgView.image = [self recognitionFaces:images[@"pitchDown"]];
//    }
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:@"正在裁剪人脸图片，请稍后..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *key in self.images.keyEnumerator) {
            UIImage *img = [self recognitionFaces:self.images[key]];
            if (img != nil) {
                self.faceImages[key] = img;
            }
            
            if (self.collectFailed == true) {
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            self.mainFaceImgView.image = self.faceImages[@"bestImage"];
            self.yawRightImgView.image = self.faceImages[@"yawRight"];
            self.yawLeftImgView.image = self.faceImages[@"yawLeft"];
            self.pitchUpImgView.image = self.faceImages[@"pitchUp"];
            self.pitchDownImgView.image = self.faceImages[@"pitchDown"];
            self.addFaceButton.hidden = self.collectFailed;
        });
    });
}

- (IBAction)returnBackClick:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)exitFaceCollect {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)recognitionFaces:(UIImage *)imageInput {
    UIImage *outputImg = nil;
    CIContext * context = [CIContext contextWithOptions:nil];
    
    CIImage * image = [CIImage imageWithCGImage:imageInput.CGImage];
    
    NSDictionary * param = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector * faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:param];
    
    NSArray * detectResult = [faceDetector featuresInImage:image];
    
    NSMutableArray *faceViewsMArray = [[NSMutableArray alloc] init];
    for (CIFaceFeature * faceFeature in detectResult) {
        UIView *faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        faceView.layer.borderColor = [UIColor clearColor].CGColor;
        faceView.layer.borderWidth = 1;
        faceView.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1.3);
        NSLog(@"face rect: %@", NSStringFromCGRect(faceFeature.bounds));
        //        NSLog(@"face rect: %@", NSStringFromCGRect(faceView.layer.frame));
        CGFloat marginTop = kMarginTop;
        CGFloat margin = marginTop * kImageWHScale; //(CGRectGetMinX(faceFeature.bounds) + CGRectGetMinY(faceFeature.bounds)) * 0.25;
//        CGFloat height = CGRectGetHeight(faceFeature.bounds) + margin + marginTop;
//        CGFloat width = height * kImageWHScale;
        CGFloat width = CGRectGetWidth(faceFeature.bounds) + margin + marginTop;
        width = MIN(width, imageInput.size.width);
        CGFloat height = width / kImageWHScale;
        CGFloat x = CGRectGetMinX(faceFeature.bounds) - margin;
        CGFloat y = CGRectGetMinY(faceFeature.bounds) - marginTop;
        CGRect rect = CGRectMake(MAX(0, x), MAX(0, y), width, height);
        NSLog(@"face rect: %@", NSStringFromCGRect(rect));
        [faceViewsMArray addObject:NSStringFromCGRect(rect)];
    }
    
    
    for (int i = 0; i< detectResult.count; i++) {
        //        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5+105*i, 400, 100, 100)];
        //        UIView *faceView = faceViewsMArray[i];
        //        CGRect faceRect = [faceView convertRect:faceView.layer.bounds toView:self.pictureImageView];
        //        UIImage *newImage = [self imageFromImage:imageInput inRect:faceRect];
        //        [imageView setImage:newImage];
        //
        //        [self.view addSubview:imageView];
        
        //        UIView *faceView = faceViewsMArray[i];
        //        [faceView setTransform:CGAffineTransformMakeScale(1, -1)];
        //        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageInput.size.width, imageInput.size.height)];
        //        CGRect faceRect = [faceView convertRect:faceView.layer.bounds toView:view];
        outputImg = [self imageFromImage:imageInput inRect:CGRectFromString(faceViewsMArray.firstObject)];
    }
    
    NSLog(@"output image: %@", outputImg);
    if (outputImg == nil) {
        self.collectFailed = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showGetFaceDataFailedAlertView];
        });
    }
    
    return outputImg;
}

- (UIImage*)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    //    CGFloat scale = image.size.width / image.size.height;
    
    //    rect = CGRectMake(CGRectGetMinX(rect) / scale, CGRectGetMinY(rect) / scale, CGRectGetWidth(rect) / scale, CGRectGetHeight(rect) / scale);
    
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage; //[self compressImage:newImage];
}

- (UIImage *)compressImage:(UIImage *)image {
    CGSize size = CGSizeMake(kUploadImageWidth, kUploadImageWidth);
    
    UIGraphicsBeginImageContext(size);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)showGetFaceDataFailedAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"采集的人脸图片不完整，请重新采集。" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self returnBackClick:nil];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (IBAction)addFaceClick:(id)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:@"正在获取可用faceid，请稍后..."];
    
    WEAK_SELF(self);
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        [[SHNetworkManager sharedNetworkManager] getAvailableFaceid:^(id  _Nullable result, ZJRequestError * _Nullable error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [SVProgressHUD dismiss];
                
                STRONG_SELF(self);
                if (error != nil) {
                    SHLogError(SHLogTagAPP, @"getAvailableFaceid failed, error: %@", error);
                    
                    [self showUploadFailedAlertView:[NSString stringWithFormat:@"获取faceid失败, error: %@", error.error_description]];
                } else {
                    SHLogInfo(SHLogTagAPP, @"result: %@", result);
                    NSString *faceid = [result[@"faceid"] stringValue];
                    if (faceid == nil) {
                        [self showUploadFailedAlertView:@"faceid为空"];
                    } else {
                        self.faceid = faceid;
                        [self showSetNameAlertView];
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

- (void)uploadHandlerWithName:(NSString *)name {
//    self.userName = name;
    [SVProgressHUD showWithStatus:@"正在上传人脸数据，请稍后..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self uploadFaceDataWithName:name];
        [self setupFaceDataToFW];
    });
}

- (void)setupFaceDataToFW {
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.faceImages.count];
    
    int totalSize = 0;
    for (NSString *key in self.faceImages.keyEnumerator) {
        UIImage *img = [self compressImage:self.faceImages[key]];
        if (img != nil) {
            NSData *data = UIImageJPEGRepresentation(img, 1.0); //UIImagePNGRepresentation(img);
            totalSize += data.length;
            [temp addObject:data];
        }
    }
    
    if (temp.count <= 0) {
        SHLogError(SHLogTagAPP, @"Face DataSet is nil.");
        
        return;
    }
    
    SHLogInfo(SHLogTagAPP, @"Face data set length: %d", totalSize);
    
    [[SHFaceDataManager sharedFaceDataManager] addFaceDataWithFaceID:self.faceid faceData:temp.copy];
}

- (void)uploadFaceDataWithName:(NSString *)name {
    UIImage *img = self.images[@"bestImage"]; //[self compressImage:self.images[@"bestImage"]];
    if (img == nil) {
        SHLogError(SHLogTagAPP, @"Main face is nil.");
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            [self showUploadFailedAlertView:@"人脸数据不存在"];
        });
        
        return;
    }
    
    NSData *data = UIImagePNGRepresentation(img);
    [[SHNetworkManager sharedNetworkManager] uploadFaceData:data faceid:self.faceid name:name finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        if (error != nil) {
            SHLogError(SHLogTagAPP, @"uploadFaceData failed, error: %@", error.error_description);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                
                [self showUploadFailedAlertView:[NSString stringWithFormat:@"上传人脸数据失败, error: %@", error.error_description]];
            });
        } else {
            [self uploadFaceDataSetWithName:name];
        }
    }];
}

- (void)uploadFaceDataSetWithName:(NSString *)name {
    NSMutableDictionary *temp = [NSMutableDictionary dictionary];
    
    for (NSString *key in self.faceImages.keyEnumerator) {
        UIImage *img = [self compressImage:self.faceImages[key]];
        if (img != nil) {
            NSData *data = UIImagePNGRepresentation(img);
            temp[key] = [data base64EncodedStringWithOptions:0];
        }
    }
    
    if (temp.count <= 0) {
        SHLogError(SHLogTagAPP, @"Face DataSet is nil.");
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            [self showUploadFailedAlertView:@"人脸集合数据不存在"];
            [self uploadFaceDataFailedHandle];
        });
        
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:temp options:0 error:nullptr];
    SHLogInfo(SHLogTagAPP, @"data length: %d", data.length);
    
    [[SHNetworkManager sharedNetworkManager] uploadFaceDataSet:data faceid:self.faceid finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (error != nil) {
                SHLogError(SHLogTagAPP, @"uploadFaceDataSet failed, error: %@", error.error_description);
                
                [self showUploadFailedAlertView:[NSString stringWithFormat:@"上传人脸集合数据失败，error: %@", error.error_description]];
                [self uploadFaceDataFailedHandle];
            } else {
                [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"kAddFacePictureSuccess", nil), name]];
                [SVProgressHUD dismissWithDelay:2.0];
                
                NSString *notificationName = kReloadFacesInfoNotification;
    
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
                
//                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                [self exitFaceCollect];
            }
        });
    }];
}

- (void)uploadFaceDataFailedHandle {
    [[SHNetworkManager sharedNetworkManager] deleteFaceDataWithFaceid:self.faceid finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        [SVProgressHUD dismiss];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [SVProgressHUD showErrorWithStatus:error.error];
                [SVProgressHUD dismissWithDelay:2.0];
            }
        });
    }];
}

- (void)showSetNameAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kSetupFaceName", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *nameTextField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        
        nameTextField = textField;
    }];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kUploadFacePicture", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = nameTextField.text;
        
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

- (void)inputEmptyAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"kFaceNameInvalid", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSetNameAlertView];
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

- (void)alreadyExistFaceInfoAlert:(NSString *)name {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:[NSString stringWithFormat:NSLocalizedString(@"kFaceAlreadyExist", nil), name] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showSetNameAlertView];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Init
- (NSMutableDictionary *)faceImages {
    if (_faceImages == nil) {
        _faceImages = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    
    return _faceImages;
}

@end
