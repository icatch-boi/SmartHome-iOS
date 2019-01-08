//
//  FRDFaceDetectionVC.m
//  FaceRecognition
//
//  Created by ZJ on 2018/9/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "FRDFaceDetectionVC.h"
#import <AVFoundation/AVFoundation.h>
#import "ZJFaceRecognition.h"
#import <Masonry.h>
#import "FRDResultHandleVC.h"
#import "FRDFaceResult.h"

static CGFloat kFaceBoxWidth = 250;
static CGFloat kFaceBoxTopHeight = 150;

@interface FRDFaceDetectionVC () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, weak) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIView *faceBoxView;
@property (nonatomic, assign) CGRect preRect;

@property (nonatomic, assign) BOOL isCapture;
@property (nonatomic, strong) UIImage *facePicture;

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *faceLayers;
@property (nonatomic, assign) CGFloat imageScale;
@property (nonatomic, assign) BOOL detectionFace;

@property (nonatomic, weak) UILabel *infoLabel;
@property (nonatomic, strong) NSMutableDictionary<NSString *, FRDFaceResult *> *facesResultMDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, FRDFaceResult *> *facesPreResultMDict;
@property (nonatomic, strong) NSArray<UIImage *> *facePictures;

@end

@implementation FRDFaceDetectionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupGUI];
    [self getAuthorization];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_captureSession startRunning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _facePicture = nil;
    _isCapture = false;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.captureSession stopRunning];
}

- (void)setupGUI {
    [self setupInfoLabel];
    [self setupSwitchButton];
}

- (void)setupSwitchButton {
    UIBarButtonItem *switchBtn = [[UIBarButtonItem alloc] initWithTitle:@"切换摄像头" style:UIBarButtonItemStylePlain target:self action:@selector(changeCameraAction)];
    self.navigationItem.rightBarButtonItem = switchBtn;
}

- (void)setupInfoLabel {
    UILabel *label = [[UILabel alloc] init];
    
//    label.hidden = YES;
    label.text = @"请正对手机";
    label.textColor = [UIColor redColor];
    
    [self.view addSubview:label];
    
    self.infoLabel = label;
    
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.mas_equalTo(kFaceBoxTopHeight - 30);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getAuthorization
{
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (videoStatus)
    {
        case AVAuthorizationStatusAuthorized:
        case AVAuthorizationStatusNotDetermined:
            [self initCamera];
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            NSLog(@"相机未授权");
            [self showMsgWithTitle:@"相机未授权" message:@"请打开设置-->隐私-->相机-->快射-->开启权限"];
            break;
        default:
            break;
    }
}

- (void)showMsgWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title   message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertVC animated:YES completion:nil];
    });
}

- (void)initCamera {
    [self setupSession];
    [_captureSession beginConfiguration];
    
    [self setupVideoDevice];
    [self setupPreviewLayer];
    
    [_captureSession commitConfiguration];
//    [_captureSession startRunning];
}

- (void)setupSession {
    _captureSession = [[AVCaptureSession alloc] init];
    
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    }
}

- (void)changeCameraAction {
    // 1. Transition Animation
    [self setupTransitionAnimation];
    
    // 2.Get current camera
    AVCaptureDevicePosition position = _videoInput.device.position == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    
    // 3.Get current device
    AVCaptureDevice *captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:position];
    
    // 4.Create new input
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:nil];
    if (newVideoInput == nil) {
        NSLog(@"Create new video input failed.");
        return;
    }
    
    // 5.Remove old input & add new input
    [self replaceVideoInputWithVideoInput:newVideoInput];
    
    _videoInput = newVideoInput;
}

- (void)replaceVideoInputWithVideoInput:(AVCaptureDeviceInput *)newVideoInput {
    [_captureSession beginConfiguration];
    
    [_captureSession removeInput:_videoInput];
    [_captureSession addInput:newVideoInput];
    
    [self resetVideoOrientation];

    [_captureSession commitConfiguration];
}

- (void)resetVideoOrientation {
    if (_dataOutput == nil || ![_captureSession.outputs containsObject:_dataOutput]) {
        NSLog(@"Data output: %@", _dataOutput);
        return;
    }
    
    AVCaptureConnection *captureConnection = [_dataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if ([captureConnection isVideoOrientationSupported]) {
        [captureConnection setVideoOrientation:[self currentVideoOrientation]];
    }
    
    // 视频稳定设置
    if ([captureConnection isVideoStabilizationSupported]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    
    // 设置输出图片方向
    captureConnection.videoOrientation = [self currentVideoOrientation];
}

- (void)setupTransitionAnimation {
    CATransition *trans = [[CATransition alloc] init];
    
    trans.type = @"oglFlip";
    trans.subtype = @"fromLeft";
    trans.duration = 0.35;
    
    [self.view.layer addAnimation:trans forKey:nil];
}

- (void)setupVideoDevice {
    _videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
    
    [self setupInput];
    [self setupDataOutput];
    [self setupMetadataOutput];
}

- (void)setupInput {
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:nil];
    
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
    }
}

- (void)setupMetadataOutput {
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_queue_create("CameraCaptureMetadataOutputDelegateQueue", NULL)];
    
    if ([_captureSession canAddOutput:metadataOutput]) {
        [_captureSession addOutput:metadataOutput];
    }
    
    metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    
    _metadataOutput = metadataOutput;
}

/// 添加数据输出
- (void)setupDataOutput
{
    // 拍摄视频输出对象
    // 初始化输出设备对象，用户获取输出数据
    _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_dataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("CameraCaptureSampleBufferDelegateQueue", NULL)];
    
    NSString *key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    
    [_dataOutput setVideoSettings:videoSettings];
    
    if ([_captureSession canAddOutput:_dataOutput]) {
        [_captureSession addOutput:_dataOutput];
        AVCaptureConnection *captureConnection = [_dataOutput connectionWithMediaType:AVMediaTypeVideo];
        
        if ([captureConnection isVideoOrientationSupported]) {
            [captureConnection setVideoOrientation:[self currentVideoOrientation]];
        }
        // 视频稳定设置
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        // 设置输出图片方向
        captureConnection.videoOrientation = [self currentVideoOrientation];
    }
}

- (void)setupFaceBox {
    UIView *faceBoxView = [[UIView alloc] init];
    
    faceBoxView.layer.borderWidth = 2;
    faceBoxView.layer.borderColor = [UIColor greenColor].CGColor;
    
    //    faceBoxView.layer.sublayerTransform = [self CATransform3DMakePerspective:1000];
    
    _faceBoxView = faceBoxView;
}

- (void)setupPreviewLayer {
    [self setupFaceBox];
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame = CGRectMake((CGRectGetWidth(self.view.frame) - kFaceBoxWidth) * 0.5, kFaceBoxTopHeight, kFaceBoxWidth, kFaceBoxWidth);
    previewLayer.cornerRadius = kFaceBoxWidth * 0.5;
    previewLayer.borderColor = [UIColor cyanColor].CGColor;
    previewLayer.borderWidth = 3;
    
    [self.view.layer insertSublayer:previewLayer atIndex:0];
    
    [previewLayer addSublayer:_faceBoxView.layer];
    
    _previewLayer = previewLayer;
    _metadataOutput.rectOfInterest = previewLayer.bounds;
}

- (AVCaptureVideoOrientation)currentVideoOrientation {
    AVCaptureVideoOrientation orientation;
    
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:{
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        }
        case UIDeviceOrientationLandscapeRight:{
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        }
        case UIDeviceOrientationLandscapeLeft:{
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        }
        default:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    return orientation;
}

/// 获取设备
- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *deviceDiscovery = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:mediaType position:position];
        NSLog(@"discovery %lu device.", (unsigned long)deviceDiscovery.devices.count);
        
        return deviceDiscovery.devices.firstObject;
    } else {
        // Fallback on earlier versions
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
        AVCaptureDevice *captureDevice = devices.firstObject;

        for (AVCaptureDevice *device in devices) {
            if (device.position == position) {
                captureDevice = device;
                break;
            }
        }
        
        return captureDevice;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"resultHandleSugue"]) {
        FRDResultHandleVC *vc = segue.destinationViewController;

        vc.picture = self.facePicture;
        vc.reset = self.isReset;
        vc.recognition = self.isRecognition;
        vc.userName = self.userName;
        vc.images = [NSArray arrayWithArray:self.facePictures];
    }
}

- (void)cleanLayer {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSString *key in self.facesResultMDict.allKeys) {
            CALayer *layer = self.facesResultMDict[key].faceLayer;
            [layer removeFromSuperlayer];
        }
        
        [self.facesResultMDict removeAllObjects];
        [self.facesPreResultMDict removeAllObjects];
    });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection {
    
    __block UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    if (self.detectionFace) {
        self.detectionFace = false;
    } else {
        [self cleanLayer];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.infoLabel.text = @"没有检测到人脸";
        });
    }
    
    if (_isCapture && image && _facePicture == nil) {
        _isCapture = false;

        NSInteger count = self.facesResultMDict.count;
        NSLog(@"----> face count: %lu", (unsigned long)count);
//        NSMutableArray<UIImage *> *tempMArray = [NSMutableArray arrayWithCapacity:count];
//
//        [self.facesResultMDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, FRDFaceResult * _Nonnull obj, BOOL * _Nonnull stop) {
//            CALayer *faceLayer = [self.facesResultMDict objectForKey:key].faceLayer;
//            UIImage *faceImage = [self reDrawOrangeImage:image withRect:faceLayer.frame];
//
//            if (faceImage) {
//                [tempMArray addObject:faceImage];
//
////                [ZJFaceRecognition faceImagesByFaceRecognition:faceImage resultCallback:^(NSInteger faceCount) {
//////                    NSLog(@"face count: %ld", (long)faceCount);
////
////                    if (faceCount) {
////                        [tempMArray addObject:faceImage];
////                    }
////                }];
//            }
//        }];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.facePicture = tempMArray.firstObject;
//            self.facePictures = tempMArray.copy;
//
//            [self performSegueWithIdentifier:@"resultHandleSugue" sender:nil];
//
//            [self cleanLayer];
//        });

        dispatch_async(dispatch_get_main_queue(), ^{
            self.facePicture = [self compressImage:image scale:image.size.width / image.size.height];
            
            [self performSegueWithIdentifier:@"resultHandleSugue" sender:nil];
            
            [self cleanLayer];
        });
    }
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    //为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space创建一个依赖于设备的rgb颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context根据这个位图的context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return image;
}

- (UIImage *)compressImage:(UIImage *)image scale:(CGFloat)scale {
    CGSize size = CGSizeMake(self.previewLayer.frame.size.width * scale, self.previewLayer.frame.size.height);
    
    UIGraphicsBeginImageContext(size);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)reDrawOrangeImage:(UIImage *)image {
    NSLog(@"image size: %@", NSStringFromCGSize(image.size));
    
    CGFloat scale = image.size.width / image.size.height;
    
    CGSize size = CGSizeMake(kFaceBoxWidth, kFaceBoxWidth);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGRect rect = CGRectMake(_preRect.origin.x , _preRect.origin.y , _preRect.size.width / scale, _preRect.size.height);
    
    CGContextAddRect(ctx, rect);
    
    CGContextClip(ctx);
    
    size = CGSizeMake(kFaceBoxWidth * scale, kFaceBoxWidth);
    rect = CGRectMake(_preRect.origin.x, 0, size.width, size.height);
    [image drawInRect:rect];
    
    UIImage *drawImage =  UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"drawImage: %@", drawImage);
    
    UIGraphicsEndImageContext();
    
    //    return [self compressImage:drawImage scale:scale];
    return drawImage;
}

- (UIImage *)reDrawOrangeImage:(UIImage *)image withRect:(CGRect)layerRect {
    NSLog(@"image: %@, rect: %@", image, NSStringFromCGRect(layerRect));

    CGFloat scale = image.size.width / image.size.height;

    image = [self compressImage:image scale:scale];

    CGSize size = CGSizeMake(kFaceBoxWidth, kFaceBoxWidth);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    CGContextRef ctx = UIGraphicsGetCurrentContext();

//    CGRect rect = CGRectMake(layerRect.origin.x , layerRect.origin.y, layerRect.size.width / scale, layerRect.size.height);
//    NSLog(@"clip rect: %@", NSStringFromCGRect(rect));

    CGContextAddRect(ctx, layerRect);

    CGContextClip(ctx);

    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];

    UIImage *drawImage =  UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"drawImage: %@", drawImage);

    UIGraphicsEndImageContext();

    return drawImage;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    NSMutableArray<AVMetadataFaceObject *> *metadataFaceObjects = [NSMutableArray array];
    
    for (AVMetadataObject *item in metadataObjects) {
        if (item.type == AVMetadataObjectTypeFace) {
            AVMetadataFaceObject *obj = (AVMetadataFaceObject *)[_previewLayer transformedMetadataObjectForMetadataObject:item];
            
            [metadataFaceObjects addObject:obj];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleOutput:metadataFaceObjects];
    });
    
    self.detectionFace = true;
}

- (BOOL)verifyRecognitionResult:(AVMetadataFaceObject *)face {
    CGFloat max = MAX(CGRectGetWidth(face.bounds), CGRectGetHeight(face.bounds));
//    BOOL success = (max / kFaceBoxWidth) >= 0.4 ? YES : NO;
    NSString *info = nil;
    
    if (max / kFaceBoxWidth < 0.3) {
        info = @"请将摄像头靠近点";
        goto verify_failed;
    }
    
    if ((CGRectGetMinX(face.bounds) >= kFaceBoxWidth * 0.15) &&
        (CGRectGetMaxX(face.bounds) <= kFaceBoxWidth * 0.95)) {
        
    } else {
        info = @"请将人脸正对圆框";
        goto verify_failed;
    }
    
    if ((CGRectGetMinY(face.bounds) >= kFaceBoxWidth * 0.15) &&
        (CGRectGetMaxY(face.bounds) <= kFaceBoxWidth * 0.95)) {
        
    } else {
        info = @"请将人脸正对圆框";
        goto verify_failed;
    }
    
    if (fabs(face.yawAngle) == 0 && fabs(face.rollAngle) == 0) {
        
    } else {
        info = @"请不要偏转或倾斜";
        goto verify_failed;
    }
    
    self.infoLabel.text = info;

    return true;
    
verify_failed:
    self.infoLabel.text = info;
    return false;
}

- (void)handleOutput:(NSArray<AVMetadataFaceObject *> *)metadataObjects {
    self.facesPreResultMDict = [NSMutableDictionary dictionaryWithDictionary:self.facesResultMDict];

    NSMutableArray<NSString *> *lostFaces = [NSMutableArray array];
    
    for (NSString *faceID in self.facesResultMDict.allKeys) {
        [lostFaces addObject:faceID];
    }
    
    for (int i = 0; i < metadataObjects.count; i++) {
        AVMetadataFaceObject *face = metadataObjects[i];
        NSString *faceID = [NSString stringWithFormat:@"%ld", (long)face.faceID];
        
        if ([lostFaces containsObject:faceID]) {
            [lostFaces removeObject:faceID];
        }
        
        FRDFaceResult *faceResult = [self.facesResultMDict objectForKey:faceID];
        if (faceResult == nil) {
            faceResult = [[FRDFaceResult alloc] init];
            faceResult.faceLayer = [self createFaceLayer];
            faceResult.faceID = faceID;
            
            [self.faceBoxView.layer addSublayer:faceResult.faceLayer];
            
            self.facesResultMDict[faceID] = faceResult;
        }
        
        faceResult.faceLayer.transform = CATransform3DIdentity;
//        faceResult.faceLayer.frame = face.bounds;
        
        faceResult.faceLayer.transform = CATransform3DMakeScale(1.3, 1.3, 1.0);
        faceResult.faceLayer.frame = face.bounds;

        BOOL success = [self verifyRecognitionResult:face];

        FRDFaceResult *facePreResult = [self.facesPreResultMDict objectForKey:faceID];
        if (facePreResult != nil) {
            if (success && CGRectEqualToRect(facePreResult.faceLayer.frame, faceResult.faceLayer.frame)) {
                faceResult.isSuccess = YES;
            }
        }
        
        // 设置偏转角
        if (face.hasYawAngle) {
            CATransform3D transform3D = [self transformDegress:face.yawAngle];
            
            faceResult.faceLayer.transform = CATransform3DConcat(faceResult.faceLayer.transform, transform3D);
        }
        
        // 设置倾斜角,侧倾角
        if (face.hasRollAngle) {
            CATransform3D transform3D = [self transformDegressForRollAngle:face.rollAngle];
            
            faceResult.faceLayer.transform = CATransform3DConcat(faceResult.faceLayer.transform, transform3D);
        }
        
        for (NSString *faceIDStr in lostFaces) {
            CALayer *faceIDLayer = self.faceLayers[faceIDStr];
            [faceIDLayer removeFromSuperlayer];
            [self.faceLayers removeObjectForKey:faceIDStr];
        }
    }
    
    __block BOOL canCapture = YES;
    [self.facesResultMDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, FRDFaceResult * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.isSuccess == NO) {
            canCapture = NO;
            *stop = YES;
        }
    }];
    
    _isCapture = canCapture;
}


- (void)handleOutput1:(NSArray<AVMetadataFaceObject *> *)metadataObjects {
    NSMutableArray<NSString *> *lostFaces = [NSMutableArray array];
    
    for (NSString *faceID in self.faceLayers.allKeys) {
        [lostFaces addObject:faceID];
    }
    
    for (int i = 0; i < metadataObjects.count; i++) {
        AVMetadataFaceObject *face = metadataObjects[i];
        NSString *faceID = [NSString stringWithFormat:@"%ld", (long)face.faceID];
        
        if ([lostFaces containsObject:faceID]) {
            [lostFaces removeObject:faceID];
        }
        
        CALayer *faceLayer = [self.faceLayers objectForKey:faceID];
        if (faceLayer == nil) {
            faceLayer = [self createFaceLayer];
            
            [self.faceBoxView.layer addSublayer:faceLayer];
            self.faceLayers[faceID] = faceLayer;
        }
        
        faceLayer.transform = CATransform3DIdentity;
        faceLayer.frame = face.bounds;
        
        //        NSLog(@"face bouds: %@", NSStringFromCGRect(face.bounds));
        //        NSLog(@"face bouds minX: %f, maxX: %f", CGRectGetMinX(face.bounds), CGRectGetMaxX(face.bounds));
        //        NSLog(@"face bouds minY: %f, maxY: %f", CGRectGetMinY(face.bounds), CGRectGetMaxY(face.bounds));
        
        faceLayer.transform = CATransform3DMakeScale(1.3, 1.3, 1.0);
        
        BOOL success = [self verifyRecognitionResult:face];
        
        if (success && CGRectEqualToRect(_preRect, faceLayer.frame)) {
            _isCapture = true;
            
            //            NSLog(@"face bouds: %@", NSStringFromCGRect(face.bounds));
            //            NSLog(@"face bouds minX: %f, maxX: %f", CGRectGetMinX(face.bounds), CGRectGetMaxX(face.bounds));
            //            NSLog(@"face bouds minY: %f, maxY: %f", CGRectGetMinY(face.bounds), CGRectGetMaxY(face.bounds));
        } else {
            //            self.captureImgView.image = nil;
        }
        
        _preRect = faceLayer.frame;
        //        _preRect = face.bounds;
        
        // 设置偏转角
        if (face.hasYawAngle) {
            CATransform3D transform3D = [self transformDegress:face.yawAngle];
            
            faceLayer.transform = CATransform3DConcat(faceLayer.transform, transform3D);
        }
        
        // 设置倾斜角,侧倾角
        if (face.hasRollAngle) {
            CATransform3D transform3D = [self transformDegressForRollAngle:face.rollAngle];
            
            faceLayer.transform = CATransform3DConcat(faceLayer.transform, transform3D);
        }
        
        for (NSString *faceIDStr in lostFaces) {
            CALayer *faceIDLayer = self.faceLayers[faceIDStr];
            [faceIDLayer removeFromSuperlayer];
            [self.faceLayers removeObjectForKey:faceIDStr];
        }
    }
}

- (CATransform3D)transformDegressForRollAngle:(CGFloat)rollAngle {
    //    NSLog(@"rollAngle: %f", rollAngle);
    
    CGFloat roll = [self degreesToRadians:rollAngle];
    
    return CATransform3DMakeRotation(roll, 0, 0, 1);
}

- (CATransform3D)transformDegress:(CGFloat)yawAngle {
    //    NSLog(@"yawAngle: %f", yawAngle);
    
    CGFloat yaw = [self degreesToRadians:yawAngle];
    CATransform3D yawTran = CATransform3DMakeRotation(yaw, 0, -1, 0);
    
    return CATransform3DConcat(yawTran, CATransform3DIdentity);
}

- (CGFloat)degreesToRadians:(CGFloat)degress {
    return degress * M_PI / 180;
}

- (CATransform3D)CATransform3DMakePerspective:(CGFloat)eyePosition {
    CATransform3D transform = CATransform3DIdentity;
    
    transform.m34 = -1 / eyePosition;
    
    return transform;
}

- (CALayer *)createFaceLayer {
    CALayer *layer = [[CALayer alloc] init];
    
    layer.borderColor = [UIColor redColor].CGColor;
    layer.borderWidth = 1;
    
    return layer;
}

#pragma mark - lazy load
- (NSMutableDictionary<NSString *,id> *)faceLayers {
    if (_faceLayers == nil) {
        _faceLayers = [NSMutableDictionary dictionary];
    }
    
    return _faceLayers;
}

- (NSMutableDictionary<NSString *,FRDFaceResult *> *)facesResultMDict {
    if (_facesResultMDict == nil) {
        _facesResultMDict = [NSMutableDictionary dictionary];
    }
    
    return _facesResultMDict;
}

@end
