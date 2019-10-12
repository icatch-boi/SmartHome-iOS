// SHQRCodeSetupDeviceVC.m

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
 
 // Created by zj on 2019/1/24 2:18 PM.
    

#import "SHQRCodeSetupDeviceVC.h"
#import "XJSetupDeviceInfoVC.h"
#import "SHNetworkManager.h"
#import "SVProgressHUD.h"
#import "SHMessage.h"

static int QRCodeStringMappingArray[] = {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
    40, 41, 42, 43, 44, 45, 46, 47, 53, 50, 48, 55, 49, 51, 52, 56, 57, 54, 58, 59,
    60, 61, 62, 63, 64, 81, 80, 87, 79, 69, 73, 82, 85, 89, 65, 76, 83, 75, 68, 74,
    70, 72, 71, 90, 77, 88, 78, 67, 66, 86, 84, 91, 92, 93, 94, 95, 96, 122, 97, 113,
    112, 108, 120, 115, 119, 111, 107, 109, 99, 100, 101, 105, 106, 110, 118, 102, 114, 117, 104, 98,
    103, 116, 121, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139,
    140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
    160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179,
    180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199,
    200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219,
    220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255
};
static NSString * const kQRCodeKey = @"SH";
static const NSTimeInterval kAutoRefreshInterval = 4 * 60;

@interface SHQRCodeSetupDeviceVC ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *exitButtonItem;
@property (weak, nonatomic) IBOutlet UIImageView *qrcodeImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) NSTimer *refreshTimer;

@end

@implementation SHQRCodeSetupDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupLocalizedString];
    [self setupGUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupNotificationHandle:) name:kSetupDeviceNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupLocalizedString {
    [_exitButtonItem setTitle:NSLocalizedString(@"kExit", nil)];
    [_nextButton setTitle:NSLocalizedString(@"kNext", nil) forState:UIControlStateNormal];
    [_nextButton setTitle:NSLocalizedString(@"kNext", nil) forState:UIControlStateHighlighted];
    _titleLabel.text = NSLocalizedString(@"kUseQRCodeSetupDeviceTitle", nil);
    _descriptionLabel.text = NSLocalizedString(@"kUseQRCodeSetupDeviceDescription", nil);
}

- (void)setupGUI {
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[[UIImage imageNamed:@"nav-logo"] imageWithTintColor:[UIColor whiteColor]] gradient:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.isAutoWay ? [self showAutoWayQRCode] : [self showQRCodeHandler];
    if (self.isAutoWay && self.isConfigWiFi == NO) {
        [self refreshTimer];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self releaseRefreshTimer];
}

- (IBAction)exitClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)nextClick:(id)sender {
    XJSetupDeviceInfoVC *vc = [[UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil] instantiateViewControllerWithIdentifier:@"XJSetupDeviceInfoVCID"];
    vc.useQRCodeSetup = YES;
    vc.wifiSSID = self.wifiSSID;
    vc.wifiPWD = self.wifiPWD;
    vc.autoWay = self.isAutoWay;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showQRCodeHandler {
    NSString *qrString = [self createQRCodeStringHandler];
    
    if (qrString != nil) {
        CIImage *qrCIImage = [self createQRForString:qrString];
        if (qrCIImage != nil) {
            UIImage *qrImage = [self createNonInterpolatedUIImageFromCIImage:qrCIImage withScale:4 * [[UIScreen mainScreen] scale]];
            
            if (qrImage != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.qrcodeImageView.image = qrImage;
                });
            }
        }
    }
}

- (NSString *)createQRCodeStringHandler {
    NSString *cameraUID = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID];
    SHLogInfo(SHLogTagAPP, @"Device id is : %@", cameraUID);
    
    if (cameraUID == nil || self.wifiPWD == nil || self.wifiSSID == nil) {
        return nil;
    }
    
    NSString *originalStr = [NSString stringWithFormat:@"%02d%@%02d%@%02d%@", (int)self.wifiSSID.length, self.wifiSSID, (int)self.wifiPWD.length, self.wifiPWD, (int)cameraUID.length, cameraUID];
    
    NSMutableString *mapString = [NSMutableString string];
    for (int i = 0 ; i < originalStr.length; i ++) {
        unichar charactor = [originalStr characterAtIndex:i];
        unichar mappingchar = QRCodeStringMappingArray[charactor];
        NSString *string =[NSString stringWithFormat:@"%c", mappingchar];
        [mapString appendString:string];
    }
    
    SHLogInfo(SHLogTagAPP, @"Mapping string: %@", mapString);
    
    return mapString.copy;
}

#pragma mark - Auto Way
- (void)showAutoWayQRCode {
    if (self.isConfigWiFi) {
        NSString *qrString = [self createAutoWayQRCodeStringWithCode:nil];
        [self showAutoWayQRCodeWithCodeString:qrString];
    } else {
        WEAK_SELF(self);
        [self getAuthorizeCodeWithCompletion:^(NSString *code) {
            if (code != nil) {
                NSString *qrString = [weakself createAutoWayQRCodeStringWithCode:code];
                [weakself showAutoWayQRCodeWithCodeString:qrString];
            }
        }];
    }
}

- (void)showAutoWayQRCodeWithCodeString:(NSString *)qrString {
    if (qrString != nil) {
        CIImage *qrCIImage = [self createQRForString:qrString];
        if (qrCIImage != nil) {
            UIImage *qrImage = [self createNonInterpolatedUIImageFromCIImage:qrCIImage withScale:4 * [[UIScreen mainScreen] scale]];
            
            if (qrImage != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.qrcodeImageView.image = qrImage;
                });
            }
        }
    }
}

- (NSString *)createAutoWayQRCodeStringWithCode:(NSString *)code {
    if (self.wifiPWD.length == 0 || self.wifiSSID.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"Wi-Fi ssid or password 不能为空"];
        [SVProgressHUD dismissWithDelay:kPromptinfoDisplayDuration];
        return nil;
    }
    
    int flag = 1;
    if (self.isConfigWiFi) {
        flag = 0;
        NSString *cameraUID = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID];
        code = cameraUID ? cameraUID : @"";
    } else {
        if (code.length == 0) {
            return nil;
        }
    }
    
    NSString *originalStr = [NSString stringWithFormat:@"%02d%@%02d%d%02d%@%02d%@%02d%@", (int)kQRCodeKey.length, kQRCodeKey, (int)(sizeof(flag)/sizeof(int)), flag, (int)self.wifiSSID.length, self.wifiSSID, (int)self.wifiPWD.length, self.wifiPWD, (int)code.length, code];
    
    NSMutableString *mapString = [NSMutableString string];
    for (int i = 0 ; i < originalStr.length; i ++) {
        unichar charactor = [originalStr characterAtIndex:i];
        unichar mappingchar = QRCodeStringMappingArray[charactor];
        NSString *string =[NSString stringWithFormat:@"%c", mappingchar];
        [mapString appendString:string];
    }
    
    SHLogInfo(SHLogTagAPP, @"Mapping string: %@", mapString);
    
    return mapString.copy;
}

- (void)getAuthorizeCodeWithCompletion:(void (^)(NSString *code))completion {
    NSArray *scopes = @[@"get_user_info", @"add_device", @"update_private_info", @"get_device_info"];
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    [[SHNetworkManager sharedNetworkManager] getAuthorizeCodeWithUsername:[[NSUserDefaults standardUserDefaults] stringForKey:kUserAccounts] password:[[NSUserDefaults standardUserDefaults] stringForKey:kUserAccountPassword] scopes:scopes completion:^(BOOL isSuccess, id  _Nullable result) {
        [SVProgressHUD dismiss];
        
        if (isSuccess) {
            NSDictionary *dict = result;
            NSString *code = nil;
            if ([dict.allKeys containsObject:@"code"]) {
                code = dict[@"code"];
            } else {
                [SVProgressHUD showErrorWithStatus:@"Response中不包含`code`值"];
                [SVProgressHUD dismissWithDelay:kPromptinfoDisplayDuration];
            }
            
            if (completion) {
                completion(code);
            }
        } else {
            ZJRequestError *error = result;
            [SVProgressHUD showErrorWithStatus:error.error_description];
            [SVProgressHUD dismissWithDelay:kPromptinfoDisplayDuration];
            
            if (completion) {
                completion(nil);
            }
        }
    }];
}

- (void)setupNotificationHandle:(NSNotification *)nc {
    SHMessage *message = nc.object;
    if (message.msgType.intValue == SHSystemMessageTypeScanSuccess || message.msgType.intValue == PushMessageTypeScanQRcodeSuccess) {
        [self nextClick:nil];
    }
}

#pragma mark - Create QRcode
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

- (UIImage *)createNonInterpolatedUIImageFromCIImage:(CIImage *)image withScale:(CGFloat)scale
{
    // Render the CIImage into a CGImage
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:image fromRect:image.extent];
    
    // Now we'll rescale using CoreGraphics
    UIGraphicsBeginImageContext(CGSizeMake(image.extent.size.width * scale, image.extent.size.width * scale));
    CGContextRef context = UIGraphicsGetCurrentContext();
    // We don't want to interpolate (since we've got a pixel-correct image)
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    // Scale from "y"
    CGContextScaleCTM(context, 1, -1);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    // Get the image out
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // Tidy up
    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);
    return [self addLogoImage:scaledImage];
}

#pragma mark - Add Log
- (UIImage *)addLogoImage:(UIImage *)superImage {
    UIImage *logo = [UIImage imageNamed:@"share-logo"];
    logo = [self changeImageAlpha:logo];
    
    return [self addImageToSuperImage:superImage withSubImage:logo andSubImagePosition:CGRectMake((superImage.size.width - logo.size.width) / 2, (superImage.size.height - logo.size.height) / 2, logo.size.width, logo.size.height)]; // 增加logo
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

- (NSTimer *)refreshTimer {
    if (_refreshTimer == nil) {
        WEAK_SELF(self);
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kAutoRefreshInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
            [weakself showAutoWayQRCode];
        }];
    }
    
    return _refreshTimer;
}

- (void)releaseRefreshTimer {
    if ([_refreshTimer isValid]) {
        [_refreshTimer invalidate];
        _refreshTimer = nil;
    }
}

@end
