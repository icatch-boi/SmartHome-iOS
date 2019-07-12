//
//  DisplayViewController.m
//  FaceSDK-Collect-WithLiveness-iOS
//
//  Created by ZJ on 2019/7/10.
//  Copyright © 2019 Baidu. All rights reserved.
//

#import "DisplayViewController.h"

static const CGFloat kImageWHScale = 716.0 / 512;

@interface DisplayViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *mainFaceImgView;
@property (weak, nonatomic) IBOutlet UIImageView *yawLeftImgView;
@property (weak, nonatomic) IBOutlet UIImageView *yawRightImgView;
@property (weak, nonatomic) IBOutlet UIImageView *pitchUpImgView;
@property (weak, nonatomic) IBOutlet UIImageView *pitchDownImgView;

@end

@implementation DisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self updateImages:self.images];
}

- (void)updateImages:(NSDictionary *)images {
    if (images[@"bestImage"] != nil) {
        NSLog(@"-- bestImage: %@", images[@"bestImage"]);
        self.mainFaceImgView.image = [self recognitionFaces:images[@"bestImage"]];
    }
    
    if (images[@"yawRight"] != nil) {
        self.yawRightImgView.image = [self recognitionFaces:images[@"yawRight"]];
    }
    
    if (images[@"yawLeft"] != nil) {
        self.yawLeftImgView.image = [self recognitionFaces:images[@"yawLeft"]];
    }
    
    if (images[@"pitchUp"] != nil) {
        self.pitchUpImgView.image = [self recognitionFaces:images[@"pitchUp"]];
    }
    
    if (images[@"pitchDown"] != nil) {
        self.pitchDownImgView.image = [self recognitionFaces:images[@"pitchDown"]];
    }
}

- (IBAction)closeClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        //        NSLog(@"face rect: %@", NSStringFromCGRect(faceFeature.bounds));
        //        NSLog(@"face rect: %@", NSStringFromCGRect(faceView.layer.frame));
        CGFloat margin = (CGRectGetMinX(faceFeature.bounds) + CGRectGetMinY(faceFeature.bounds)) * 0.25;
        CGFloat height = CGRectGetHeight(faceFeature.bounds) + margin * 2;
        CGFloat width = height * kImageWHScale;
        CGRect rect = CGRectMake(CGRectGetMinX(faceFeature.bounds) - margin, CGRectGetMinY(faceFeature.bounds) - margin, width, height);
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
        [self showGetFaceDataFailedAlertView];
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
    CGSize size = CGSizeMake(224, 224);
    
    UIGraphicsBeginImageContext(size);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)showGetFaceDataFailedAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"采集的图片不完整，请重新采集。" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self closeClick:nil];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
