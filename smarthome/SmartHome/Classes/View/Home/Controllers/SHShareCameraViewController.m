//
//  SHShareCameraViewController.m
//  SmartHome
//
//  Created by 莊志銘 on 2017/11/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHShareCameraViewController.h"

static const NSTimeInterval kAuthorityDeadline = 7 * 86400;
static const NSTimeInterval kQRDeadline = 120;
static NSString * const kSaveQRImageName = @"shareQR";
static const CGFloat kLogoImageWidth = 42.5 * UIScreen.scale;

@interface SHShareCameraViewController () <UITextFieldDelegate>
@property (nonatomic) AVPlayer *avPlayer;
@property (strong,nonatomic) NSDate *start;
@property (weak, nonatomic) IBOutlet UIButton *shareQRButton;
@property (weak, nonatomic) IBOutlet UIButton *shareEmailButton;

@property (weak, nonatomic) IBOutlet UITextField *qrDeadlineField;
@property (weak, nonatomic) IBOutlet UITextField *cameraDeadlineField;
@property (weak, nonatomic) IBOutlet UIButton *reCreateQRBtn;
@property (weak, nonatomic) IBOutlet UILabel *shareTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *qrDeadlineLab;
@property (weak, nonatomic) IBOutlet UILabel *cameraDeadlineLab;
@property (weak, nonatomic) IBOutlet UIButton *updateButton;

@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, assign) NSTimeInterval qrUseDeadline;
@property (nonatomic, assign) NSTimeInterval cameraUseDeadline;

@end

@implementation SHShareCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareQRClick:)];
    
    [self setupGUI];
    [self initParameter];
}

- (void)setupGUI {
    [_reCreateQRBtn setCornerWithRadius:_reCreateQRBtn.bounds.size.height * 0.25 masksToBounds:YES];
    [_reCreateQRBtn setBorderWidth:1.0 borderColor:_reCreateQRBtn.titleLabel.textColor];
    
    _qrDeadlineField.delegate = self;
    _cameraDeadlineField.delegate = self;
    
    _shareTitleLabel.text = NSLocalizedString(@"kShareCameraInfo", nil);
    _qrDeadlineLab.text = [NSString stringWithFormat:@"%@(min)", NSLocalizedString(@"kQRCodeDeadline", nil)];
    _cameraDeadlineLab.text = [NSString stringWithFormat:@"%@(day)", NSLocalizedString(@"kCameraDeadline", nil)];
    _qrDeadlineField.placeholder = [NSString stringWithFormat:@"%@2min", NSLocalizedString(@"kDefault", nil)];
    _cameraDeadlineField.placeholder = [NSString stringWithFormat:@"%@7day", NSLocalizedString(@"kDefault", nil)];
    [self setButtonTitle:_reCreateQRBtn title:NSLocalizedString(@"kRedrawShareQRCode", nil)];
    [self setButtonTitle:_updateButton title:NSLocalizedString(@"kUpdateQRCodeTips", nil)];
    _updateButton.titleLabel.numberOfLines = 0;
    _updateButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (void)initParameter {
    _qrUseDeadline = kQRDeadline;
    _cameraUseDeadline = kAuthorityDeadline;
    
    _qrDeadlineField.text = [NSString stringWithFormat:@"%.0f", _qrUseDeadline / 60];
    _cameraDeadlineField.text = [NSString stringWithFormat:@"%.0f", _cameraUseDeadline / 86400];
}

//取消第一响应者
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.qrImage.image = [self createQRImage];
}

- (IBAction)updateQRClick:(id)sender {
    self.qrImage.image = [self createQRImage];
}

- (IBAction)reCreateClick:(id)sender {
    [_qrDeadlineField resignFirstResponder];
    [_cameraDeadlineField resignFirstResponder];
    
    NSRange qrDeadlineRange = [_qrDeadlineField.text rangeOfString:@"[0-9.]{1,8}" options:NSRegularExpressionSearch];
    NSRange cameraDeadlineRange = [_cameraDeadlineField.text rangeOfString:@"[0-9.]{1,8}" options:NSRegularExpressionSearch];
    
    if (qrDeadlineRange.location == NSNotFound || cameraDeadlineRange.location == NSNotFound) {
        [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kInvalidInputParameters", @"") showTime:2.0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self initParameter];
        });
    } else {
        int qrDeadline = [_qrDeadlineField.text floatValue];
        int cameraDeadline = [_cameraDeadlineField.text floatValue];
        
        if (qrDeadline < 0.1 || cameraDeadline < 0.1) {
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kTimeTooShort", @"") showTime:2.0];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self initParameter];
            });
        } else {
            _qrUseDeadline = 60 * qrDeadline;
            _cameraUseDeadline = 86400 * cameraDeadline;
            
            [self updateQRClick:nil];
        }
    }
}

- (IBAction)shareQRClick:(UIBarButtonItem *)sender {
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

- (UIImage *)createQRImage {
    NSDate *authorityDate = [NSDate dateWithTimeIntervalSinceNow:_cameraUseDeadline];
    NSDate *qrDeadlineDate = [NSDate dateWithTimeIntervalSinceNow:_qrUseDeadline];
    NSString *dateFormat = @"yyyyMMddHHmmss";
    UIImage *qrImage = nil;
    
    // show the camera uid on label
    self.uidlabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"kDeviceName", @""), self.camera.cameraName];
    
#if USE_ENCRYP
    NSString *qrString = [[SHQRManager sharedQRManager] getQRStringToSharing:self.camera.cameraToken authority:[authorityDate convertToStringWithFormat:dateFormat] qrDeadline:[qrDeadlineDate convertToStringWithFormat:dateFormat]];
#else
    NSString *qrString = [[SHQRManager sharedQRManager] getQRStringToSharing:self.camera.cameraUid authority:[authorityDate convertToStringWithFormat:dateFormat] qrDeadline:[qrDeadlineDate convertToStringWithFormat:dateFormat]];
#endif
    
    if (qrString) {
        // Generate the image
        CIImage *qrCode = [self createQRForString:qrString/*self.cameraUid*/];
        
        if (qrCode) {
            // Convert to an UIImage
            qrImage = [self createNonInterpolatedUIImageFromCIImage:qrCode withScale:2*[[UIScreen mainScreen] scale]];
            
            if (qrImage) {
                [self writeImageDataToFile:qrImage andName:kSaveQRImageName];
                return qrImage;
            }
        }
    }
    
    self.uidlabel.text = NSLocalizedString(@"kGenerateQRCodeFailed", @"");
    self.shareQRButton.enabled = NO;
    self.shareEmailButton.enabled = NO;
    
    return [UIImage imageNamed:@"empty_photo"];
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
    NSLog(@"Write QRData to file is : %@", isSuccess ? @"Succeed." : @"Failed.");
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
- (CIImage *)createQRForString:(NSString *)qrString
{
    // Need to convert the string to a UTF-8 encoded NSData object
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Create the filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // Set the message content and error-correction level
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    // Send the image back
    return qrFilter.outputImage;
}

- (UIImage *)addLogoImage:(UIImage *)superImage {
    UIImage *logo = [UIImage imageNamed:@"logo_icatchtek_alpha"];
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

- (UIImage *)imageWithCornerRadius:(CGFloat)cornerRadius image:(UIImage *)image
{
    CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 1.0);
    [[UIBezierPath bezierPathWithRoundedRect:frame
                                cornerRadius:cornerRadius] addClip];
    // 画图
    [image drawInRect:frame];
    // 获取新的图片
    UIImage *im = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return im;
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

- (void)itemDidFinishPlaying:(NSNotification *)notification {
    AVPlayerItem *player = [notification object];
    [player seekToTime:kCMTimeZero completionHandler:nil];
    //[player seekToTime:kCMTimeZero];
}

#pragma mark - UITextFieldDelegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - email
-(void)newEmail{
    
    //建立物件與指定代理
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    if (controller == nil) {
        return;
    }
    
    controller.mailComposeDelegate = self;
    NSString * email = self.shareEmail.text;
    
    //設定收件人與主旨等資訊
    [controller setToRecipients:[NSArray arrayWithObjects:email, nil]];
    [controller setSubject:@"Share new camera to you"];
    
    //設定內文並且不使用HTML語法
    NSString *msg = [NSString stringWithFormat:@"Welcome<BR><br>SmartHome want to share a new door bell camera to you.<BR>You should install <B>iCatch SmartHome APP</B> from Apple Store or Google Play.<BR><BR>After install completed, launch the app and tape + on the title bar to add camera.<BR><BR>There are two way for you to add camera.<BR><BR>1. Scan QR code.<BR>2. Manually input this code %@",self.camera.cameraUid];
    [controller setMessageBody:msg isHTML:YES];
    
    
    //加入圖片
    //UIImage *theImage = [UIImage imageNamed:@"image.png"];
    //NSData *imageData = UIImagePNGRepresentation(self.qrImage.image);
    NSData *jpegData = UIImageJPEGRepresentation(self.qrImage.image, 1.0);
    [controller addAttachmentData:jpegData mimeType:@"image/jpeg" fileName:@"image.jpg"];
    //顯示電子郵件畫面
    [self presentViewController:controller animated:YES completion:nil];
    
}
//此為內建函式
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (IBAction)doShare:(id)sender {
    [self newEmail];
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
