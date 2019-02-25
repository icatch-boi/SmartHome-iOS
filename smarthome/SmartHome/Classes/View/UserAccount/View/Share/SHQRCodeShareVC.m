//
//  SHQRCodeShareVC.m
//  SmartHome
//
//  Created by ZJ on 2018/3/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHQRCodeShareVC.h"
#import "SHNetworkManagerHeader.h"
#import "ShareCommonHeader.h"

static const CGFloat kLogoImageWidth = 42.5 * UIScreen.scale;
static NSString * const kSaveQRImageName = @"shareQR";

@interface SHQRCodeShareVC ()

@property (weak, nonatomic) IBOutlet UILabel *describeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;

@property (weak, nonatomic) IBOutlet UIButton *qrCodeUpdateBtn;
@property (weak, nonatomic) IBOutlet UILabel *qrCodeDescriptionLabel;

@property (nonatomic) MBProgressHUD *progressHUD;

@end

@implementation SHQRCodeShareVC

+ (instancetype)qrCodeShareVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kUserAccountStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"SHQRCodeShareVCID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupLocalizedString];
    [self setupGUI];
}

- (void)setupLocalizedString {
    _describeLabel.text = NSLocalizedString(@"kShareDoorbellToYourFamilyOrFriends", nil);
    _qrCodeDescriptionLabel.text = NSLocalizedString(@"kQRCodeDescription", nil);
    [_qrCodeUpdateBtn setTitle:NSLocalizedString(@"kRedrawShareQRCode", nil) forState:UIControlStateNormal];
    [_qrCodeUpdateBtn setTitle:NSLocalizedString(@"kRedrawShareQRCode", nil) forState:UIControlStateHighlighted];
}

- (void)setupGUI {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareQRClick:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:self action:@selector(close) isBack:NO];
    
    [_qrCodeUpdateBtn setCornerWithRadius:_qrCodeUpdateBtn.bounds.size.height * 0.25 masksToBounds:NO];
}

- (void)close {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self createShareQRCodeImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updateClick:(id)sender {
   [self createShareQRCodeImage];
}

- (void)createShareQRCodeImage {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        if (_camera.id != nil) {
            NSString *randomCodeString = [[NSProcessInfo processInfo] globallyUniqueString];
            NSTimeInterval shareDeadline = [[NSDate date] timeIntervalSince1970] + kShareDuration;
            NSDictionary *dict = @{@"cameraId" : _camera.id,
                                   @"invitationCode" : randomCodeString,
                                   @"shareDeadline" : @(shareDeadline),
                                   @"accountName" : [SHNetworkManager sharedNetworkManager].userAccount.screen_name,
                                   };
            NSData *qrData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
            
            if (qrData) {
                // Generate the image
                CIImage *qrCode = [self createQRForString:qrData/*self.cameraUid*/];
                
                if (qrCode) {
                    // Convert to an UIImage
                    UIImage *qrImage = [self createNonInterpolatedUIImageFromCIImage:qrCode withScale:2 * [[UIScreen mainScreen] scale]];
                    
                    if (qrImage) {
                        [[SHNetworkManager sharedNetworkManager] shareCameraWithCameraID:_camera.id viaCode:randomCodeString duration:kShareDuration userLimits:0 completion:^(BOOL isSuccess, id  _Nullable result) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (isSuccess) {
                                    [self.progressHUD hideProgressHUD:YES];
                                    _qrCodeImageView.image = qrImage;
                                    [self writeImageDataToFile:qrImage andName:kSaveQRImageName];
                                } else {
                                    Error *error = result;
                                    
                                    self.progressHUD.detailsLabelText = [SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code]; //error.error_description;
                                    [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kGenerateQRCodeFailed", nil) showTime:2.0];
                                    self.navigationItem.rightBarButtonItem.enabled = NO;
                                }
                            });
                        }];
                        return;
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kGenerateQRCodeFailed", nil) showTime:2.0];
            _qrCodeImageView.image = [UIImage imageNamed:@"empty_photo"];
        });
    });
}

/*********************** Write UIImage to local *************************/
- (void)writeImageDataToFile:(UIImage *)image andName:(NSString *)fileName {
    // Create paths to output images
    NSString *pngPath = [NSString stringWithFormat:@"%@%@.png", NSTemporaryDirectory(), fileName];
    //NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.jpg", fileName]];
    
    // Write a UIImage to JPEG with minimum compression (best quality)
    // The value 'image' must be a UIImage object
    // The value '1.0' represents image compression quality as value from 0.0 to 1.0
    //[UIImageJPEGRepresentation(image, 1.0) writeToFile:jpgPath atomically:YES];
    
    // Write image to PNG
    BOOL isSuccess = [UIImagePNGRepresentation(image) writeToFile:pngPath atomically:YES];
    SHLogInfo(SHLogTagAPP, @"Write QRData to file is : %@", isSuccess ? @"Succeed." : @"Failed.");
}

- (void)shareQRClick:(UIBarButtonItem *)sender {
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@.png", NSTemporaryDirectory(), kSaveQRImageName]];
    
    if (url) {
        UIActivityViewController *activityVc = [[UIActivityViewController alloc]initWithActivityItems:@[url] applicationActivities:nil];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:activityVc animated:YES completion:nil];
        } else {
            // Create pop up
            UIPopoverController *activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityVc];
            // Show UIActivityViewController in popup
            //            UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithCustomView:sender];
            [activityPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

#pragma mark - qr code
- (UIImage *)createNonInterpolatedUIImageFromCIImage:(CIImage *)image withScale:(CGFloat)scale
{
    // Render the CIImage into a CGImage
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:image fromRect:image.extent];
    
    // Now we'll rescale using CoreGraphics
    UIGraphicsBeginImageContext(CGSizeMake(image.extent.size.width * scale, image.extent.size.width * scale));
    CGContextRef context = UIGraphicsGetCurrentContext();
    // We don't want to interpolate (since we've got a pixel-correct image)
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    // Get the image out
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // Tidy up
    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);
    return [self addLogoImage:scaledImage];
}

- (CIImage *)createQRForString:(NSData *)qrData
{
    // Need to convert the string to a UTF-8 encoded NSData object
//    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Create the filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // Set the message content and error-correction level
    [qrFilter setValue:qrData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    // Send the image back
    return qrFilter.outputImage;
}

- (UIImage *)addLogoImage:(UIImage *)superImage {
    UIImage *logo = [UIImage imageNamed:@"share-logo"];
    logo = [self changeImageAlpha:logo];
    
    return [self addImageToSuperImage:superImage withSubImage:logo andSubImagePosition:CGRectMake((superImage.size.width - kLogoImageWidth) / 2, (superImage.size.height - kLogoImageWidth) / 2, kLogoImageWidth, kLogoImageWidth)]; // 增加logo
}

- (UIImage *)addImageToSuperImage:(UIImage *)superImage withSubImage:(UIImage *)subImage andSubImagePosition:(CGRect)posRect{
    
    UIGraphicsBeginImageContext(superImage.size);
    [superImage drawInRect:CGRectMake(0, 0, superImage.size.width, superImage.size.height)];
    //四个参数为水印图片的位置
    [subImage drawInRect:posRect];
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultingImage;
}

- (UIImage *)changeImageAlpha:(UIImage *)image {
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIGraphicsBeginImageContext(rect.size);
    
    //创建路径并获取句柄
    CGMutablePathRef path = CGPathCreateMutable();
    //将矩形添加到路径中
    CGPathAddRect(path, NULL, rect);
    //获取上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //将路径添加到上下文
    CGContextAddPath(ctx, path);
    
    //设置矩形填充色
    [[UIColor whiteColor] setFill];
    //矩形边框颜色
    [[UIColor whiteColor] setStroke];
    //边框宽度
    CGContextSetLineWidth(ctx, 0);
    //绘制
    CGContextDrawPath(ctx, kCGPathFillStroke);
    CGPathRelease(path);
    
    [image drawInRect:rect];
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultingImage;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view];
    }
    
    return _progressHUD;
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
