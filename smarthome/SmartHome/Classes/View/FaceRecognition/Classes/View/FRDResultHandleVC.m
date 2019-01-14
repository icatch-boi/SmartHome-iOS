//
//  FRDUploadViewController.m
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "FRDResultHandleVC.h"
#import "SVProgressHUD.h"
#import "SHNetworkManager+SHFaceHandle.h"
#import <Masonry.h>
#import "FRDCommonHeader.h"
#import "FaceCollectionViewCell.h"
#import "FRDFaceData.h"

static CGFloat kFaceCellWidth = 110;
static CGFloat kFaceCellHeight = 140;

@interface FRDResultHandleVC () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, FaceCollectionViewCellDelete>

@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *facesCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *recognitionNumLabel;

@property (nonatomic, strong) NSMutableArray<FRDFaceData *> *facesMarray;

@end

@implementation FRDResultHandleVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
}

- (void)setupGUI {
    self.pictureImageView.image = self.picture;
    
    NSString *infoString = @"Setup face picture";
    
    if (self.reset) {
        infoString = [NSString stringWithFormat:@"Reset \"%@\" face picture", self.userName];
    } else if (self.recognition) {
        infoString = @"Face Recognition";
        
//        [self faceRecognitionHandler];
    }
    
    [self recognitionClick:nil];

    self.infoLabel.text = infoString;
    
    [self setupRecognitionBtn];
    [self setupFacesCollectionView];
    self.recognitionNumLabel.hidden = self.recognition;
    self.navigationItem.rightBarButtonItem.enabled = self.recognition;
}

- (void)setupRecognitionBtn {
    UIBarButtonItem *recognitionBtn = [[UIBarButtonItem alloc] initWithTitle:@"Recognition" style:UIBarButtonItemStylePlain target:self action:@selector(recognitionClick:)];
    
    self.navigationItem.rightBarButtonItem = recognitionBtn;
}

- (void)setupFacesCollectionView {
    self.facesCollectionView.delegate = self;
    self.facesCollectionView.dataSource = self;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    layout.itemSize = CGSizeMake(kFaceCellWidth, kFaceCellHeight);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
//    layout.sectionInset = UIEdgeInsetsMake(2, 10, 2, 10);
    
    self.facesCollectionView.collectionViewLayout = layout;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)faceRecognitionHandler {
    [SVProgressHUD showWithStatus:@"正在识别..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    NSData *data = UIImageJPEGRepresentation(self.picture, 1.0);
    
    WEAK_SELF(self)
    [[SHNetworkManager sharedNetworkManager] faceRecognitionWithPicture:data deviceID:@"ZJDEVICE" finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            NSString *infoString = @"识别出错, 请重试";
            if (error != nil) {
                NSLog(@"error: %@", error);
                
                [SVProgressHUD showErrorWithStatus:error.error];
                [SVProgressHUD dismissWithDelay:2.0];
                
                if (error.error_description) {
                    infoString = error.error_description;
                }
            } else {
//                NSLog(@"result: %@", result);
                infoString = [NSString stringWithFormat:@"识别到: %@", result[@"name"]];
            }
            
            weakself.infoLabel.text = infoString;
        });
    }];
}

- (void)uploadHandlerWithName:(NSString *)name {
    self.userName = name;
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    NSData *data = UIImageJPEGRepresentation(self.picture, 1.0);
    
    WEAK_SELF(self);
    if (self.reset) {
        [[SHNetworkManager sharedNetworkManager] replaceFacePicture:data name:name finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
            [weakself resultHandler:error];
        }];
    } else {
        [[SHNetworkManager sharedNetworkManager] uploadFacePicture:data name:name finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
            [weakself resultHandler:error];
        }];
    }
}

- (void)resultHandler:(ZJRequestError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        
        if (error != nil) {
            NSLog(@"error: %@", error);
            
            [SVProgressHUD showErrorWithStatus:error.error];
            [SVProgressHUD dismissWithDelay:2.0];
        } else {
//            [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
            [SVProgressHUD showSuccessWithStatus:self.reset ? [NSString stringWithFormat:@"Reset [%@] face image successful.", self.userName] : [NSString stringWithFormat:@"Add [%@] face image successful.", self.userName]];
            [SVProgressHUD dismissWithDelay:2.0];
            
            if (self.facesMarray.count == 1) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            
//            NSString *notificationName = kReloadFacesInfoNotification;
//            if (self.reset) {
//                notificationName = kUpdateFacesInfoNotification;
//            }
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
            [self updateFaceData];
            [self.facesCollectionView reloadData];
        }
    });
}

- (void)updateFaceData {
    [self.facesMarray enumerateObjectsUsingBlock:^(FRDFaceData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.picture == obj.faceImage) {
            obj.alreadyAdd = YES;
            
            NSString *title = @"Add success";
            if (self.reset) {
                title = @"Reset success";
            }
            obj.title = title;
            
            *stop = YES;
        }
    }];
}

- (IBAction)sureClick:(id)sender {
    if (self.reset) {
        [self uploadHandlerWithName:self.userName];
        return;
    }
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Tips" message:@"Please enter a name" preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *nameTextField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        
        nameTextField = textField;
    }];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Upload" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

- (void)alreadyExistFaceInfoAlert:(NSString *)name {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Warning" message:[NSString stringWithFormat:@"Already exist \" %@ \" facial info, please change a name.", name] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sureClick:nil];
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
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Input is empty, please enter a valid name" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sureClick:nil];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (IBAction)recognitionClick:(id)sender {
//    [self faceRecognitionHandler];
    if (self.recognition) {
        [self faceRecognitionHandler];
    } else {
        [self recognitionFaces];
    }
}

- (void)recognitionFaces {
    [self.facesMarray removeAllObjects];
    CIContext * context = [CIContext contextWithOptions:nil];
    
    UIImage * imageInput = [self.pictureImageView image];
    CIImage * image = [CIImage imageWithCGImage:imageInput.CGImage];
    
    NSDictionary * param = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    CIDetector * faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:param];
    
    NSArray * detectResult = [faceDetector featuresInImage:image];
    
    UIView * resultView = [[UIView alloc] initWithFrame:self.pictureImageView.frame];
    [self.view addSubview:resultView];
    
    NSMutableArray *faceViewsMArray = [[NSMutableArray alloc] init];
    for (CIFaceFeature * faceFeature in detectResult) {
        UIView *faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        faceView.layer.borderColor = [UIColor clearColor].CGColor;
        faceView.layer.borderWidth = 1;
        [resultView addSubview:faceView];
        faceView.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1.3);
        [faceViewsMArray addObject:faceView];
        
        if (faceFeature.hasLeftEyePosition) {
            UIView * leftEyeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
            [leftEyeView setCenter:faceFeature.leftEyePosition];
            leftEyeView.layer.borderWidth = 1;
            leftEyeView.layer.borderColor = [UIColor clearColor].CGColor;
            [resultView addSubview:leftEyeView];
        }
        
        if (faceFeature.hasRightEyePosition) {
            UIView * rightEyeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
            [rightEyeView setCenter:faceFeature.rightEyePosition];
            rightEyeView.layer.borderWidth = 1;
            rightEyeView.layer.borderColor = [UIColor clearColor].CGColor;
            [resultView addSubview:rightEyeView];
        }
        
        if (faceFeature.hasMouthPosition) {
            UIView * mouthView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 5)];
            [mouthView setCenter:faceFeature.mouthPosition];
            mouthView.layer.borderWidth = 1;
            mouthView.layer.borderColor = [UIColor clearColor].CGColor;
            [resultView addSubview:mouthView];
        }
    }
    
    [resultView setTransform:CGAffineTransformMakeScale(1, -1)];
    
    for (int i = 0; i< detectResult.count; i++) {
//        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5+105*i, 400, 100, 100)];
//        UIView *faceView = faceViewsMArray[i];
//        CGRect faceRect = [faceView convertRect:faceView.layer.bounds toView:self.pictureImageView];
//        UIImage *newImage = [self imageFromImage:imageInput inRect:faceRect];
//        [imageView setImage:newImage];
//
//        [self.view addSubview:imageView];
        
        UIView *faceView = faceViewsMArray[i];
        CGRect faceRect = [faceView convertRect:faceView.layer.bounds toView:self.pictureImageView];
        UIImage *newImage = [self imageFromImage:imageInput inRect:faceRect];
        
        if ([self calulateImageFileSize:newImage] < 15 * 1024) {
            SHLogError(SHLogTagAPP, @"Face image to small.");
            [self faceImageTooSmallHandlerWithFaceView:faceView rect:faceRect];
            continue;
        }
        
        FRDFaceData *faceData = [[FRDFaceData alloc] init];
        faceData.faceImage = newImage;
        NSString *title = @"Add";
        if (self.reset) {
            title = @"Reset";
        }
        faceData.title = title;
        
        [self.facesMarray addObject:faceData];
    }

    NSLog(@"%@", [NSString stringWithFormat:@"人脸数：%lu",(unsigned long)self.facesMarray.count]);
    NSString *message = @"没有发现人脸，请重新拍摄。";
    
    if (detectResult.count> 0) {
       message = [NSString stringWithFormat:@"图中人脸个数：%lu个，请选择要操作的人脸图像。",(unsigned long)self.facesMarray.count];
    }
    
    _recognitionNumLabel.text = message;
    [self.facesCollectionView reloadData];
}

- (void)faceImageTooSmallHandlerWithFaceView:(UIView *)faceView rect:(CGRect)rect {
    UILabel *label = [self createTipsLabel];
    
    label.center = CGPointMake(CGRectGetWidth(rect) * 0.5, CGRectGetHeight(rect) * 0.5);
    
    [faceView addSubview:label];
}

- (UILabel *)createTipsLabel {
    UILabel *label = [[UILabel alloc] init];
    
    label.text = @"Too small";
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = [UIColor yellowColor];
    [label sizeToFit];
    [label setTransform:CGAffineTransformMakeScale(1, -1)];

    return label;
}

- (double)calulateImageFileSize:(UIImage *)image {
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        data = UIImageJPEGRepresentation(image, 1.0);//需要改成0.5才接近原图片大小，原因请看下文
    }
    double dataLength = [data length] * 1.0;
    NSArray *typeArray = @[@"bytes",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB",@"ZB",@"YB"];
    NSInteger index = 0;
    while (dataLength > 1024) {
        dataLength /= 1024.0;
        index ++;
    }
    
    SHLogInfo(SHLogTagAPP, @"image = %.3f %@",dataLength,typeArray[index]);
    return data.length;
}

- (UIImage*)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    CGFloat scale = [self getScale:self.pictureImageView image:image];
    
    rect = CGRectMake(CGRectGetMinX(rect) / scale, CGRectGetMinY(rect) / scale, CGRectGetWidth(rect) / scale, CGRectGetHeight(rect) / scale);
    
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}

- (CGFloat)getScale:(UIImageView *)imageView image:(UIImage *)image {
    CGSize viewSize = imageView.frame.size;
    CGSize imageSize = image.size;
    
    CGFloat widthScale = imageSize.width / viewSize.width;
    CGFloat heightScale = imageSize.height / viewSize.height;
    
    return MAX(widthScale, heightScale);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.facesMarray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"FaceCollectionViewCellID";
    
    FaceCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    cell.faceData = self.facesMarray[indexPath.row];
    cell.delegate = self;
    
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat margin = self.facesMarray.count > 1 ? 10 : (CGRectGetWidth(self.view.bounds) - kFaceCellWidth) * 0.5;
    
    return UIEdgeInsetsMake(2, margin, 2, margin);
}

- (void)opertionClickWithFaceCollectionViewCell:(FaceCollectionViewCell *)cell {
    self.picture = cell.faceData.faceImage;
    
    [self sureClick:nil];
}

- (NSMutableArray<FRDFaceData *> *)facesMarray {
    if (_facesMarray == nil) {
        _facesMarray = [[NSMutableArray alloc] init];
    }
    
    return _facesMarray;
}

@end
