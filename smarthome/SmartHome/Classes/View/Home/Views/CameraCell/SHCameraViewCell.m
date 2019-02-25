// SHCameraViewCell.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by zj on 2018/3/21 下午2:06.
    

#import "SHCameraViewCell.h"

static UIColor * const kDefaultBackgroundColor = [UIColor ic_colorWithHex:0xF2F2F2];
static UIColor * const kSelectedBackgroundColor = [UIColor ic_colorWithHex:0x9b9b9b alpha:0.65];
static UIColor * const kButtonDefaultBackgroundColor = [UIColor ic_colorWithHex:0xF2F2F2];
static UIColor * const kButtonSelectedBackgroundColor = [UIColor ic_colorWithHex:kButtonThemeColor];

@interface SHCameraViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *cameraNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cameraThumbnail;
@property (weak, nonatomic) IBOutlet UIView *footBarView;
@property (weak, nonatomic) IBOutlet UIButton *messageBtn;
@property (weak, nonatomic) IBOutlet UIButton *albumBtn;
@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
@property (weak, nonatomic) IBOutlet UILabel *lastPreviewTime;
@property (weak, nonatomic) IBOutlet UILabel *cameraInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, strong) UILabel *sharedLabel;

@end

@implementation SHCameraViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self setupGUI];
}

- (void)setupGUI {
    _cameraNameLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    _lastPreviewTime.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [_cameraNameLabel setCornerWithRadius:5.0 masksToBounds:YES];
    [_lastPreviewTime setCornerWithRadius:5.0 masksToBounds:YES];
    
    [self addGestureEvent];
    
    _cameraThumbnail.backgroundColor = kDefaultBackgroundColor;
}

- (void)addGestureEvent {
    _cameraThumbnail.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_cameraThumbnail addGestureRecognizer:singleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    longPress.minimumPressDuration = 2.0;
    [_cameraThumbnail addGestureRecognizer:longPress];
    [singleTap requireGestureRecognizerToFail:longPress];
}

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    
    //do something....
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self startPreviewAction:nil];
    }
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    SHLogInfo(SHLogTagAPP, @"longPressGesture");
    if ([self.delegate respondsToSelector:@selector(longPressDeleteCamera:)]) {
        [self.delegate longPressDeleteCamera:self];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setViewModel:(SHCameraViewModel *)viewModel {
    _viewModel = viewModel;
    
    _cameraNameLabel.text = [[@" " stringByAppendingString:viewModel.cameraObj.camera.cameraName] stringByAppendingString:@" "];
    _lastPreviewTime.text = viewModel.cameraObj.camera.pvTime ? [[@" " stringByAppendingString:viewModel.cameraObj.camera.pvTime] stringByAppendingString:@" "] : viewModel.cameraObj.camera.pvTime;
    
    UIImage *img = viewModel.cameraObj.camera.thumbnail;

    _cameraThumbnail.image = [img ic_imageWithSize:_cameraThumbnail.bounds.size backColor:self.backgroundColor];
    _cameraThumbnail.highlightedImage = [self createHighlightedImageWithImage:_cameraThumbnail.image];
    
    _cameraInfoLabel.text = viewModel.cameraObj.camera.operable ? @"" : @"From sharing";
    _shareBtn.enabled = (viewModel.cameraObj.camera.operable == 1) ? YES : NO;
    (viewModel.cameraObj.camera.operable == 1) ? [self removeShareDescriptionLabel] : [self addShareDescriptionLabel];
}

- (UILabel *)sharedLabel {
    if (_sharedLabel == nil) {
        _sharedLabel = [[UILabel alloc] init];
        _sharedLabel.text = @"Shared";
        _sharedLabel.font = [UIFont systemFontOfSize:12.0];
        _sharedLabel.textColor = [UIColor ic_colorWithHex:kThemeColor];
    }
    
    return _sharedLabel;
}

- (void)layoutSharedLabel {
    CGRect rect = [_footBarView convertRect:_shareBtn.frame toView:_shareBtn];
    CGFloat w = [SHTool stringSizeWithString:self.sharedLabel.text font:self.sharedLabel.font].width;
    CGFloat h = [SHTool stringSizeWithString:self.sharedLabel.text font:self.sharedLabel.font].height;
    CGFloat x = (CGRectGetWidth(rect) - w) * 0.5;
    CGFloat y = CGRectGetHeight(rect) - h;
    
    self.sharedLabel.frame = CGRectMake(x, y, w, h);
}

- (void)addShareDescriptionLabel {
    [self.shareBtn addSubview:self.sharedLabel];
    [self layoutSharedLabel];
}

- (void)removeShareDescriptionLabel {
    for (UIView *v in self.shareBtn.subviews) {
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)v;
            if ([label.text isEqualToString:@"Shared"]) {
                [v removeFromSuperview];
            }
        }
    }
}

- (UIImage *)createHighlightedImageWithImage:(UIImage *)image {
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *superImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setValue:superImage forKey:kCIInputImageKey];
    
    // 修改亮度   -1---1   数越大越亮
//    [lighten setValue:@(0.2) forKey:@"inputBrightness"];
//
//    // 修改饱和度  0---2
//    [lighten setValue:@(0.5) forKey:@"inputSaturation"];
    
    // 修改对比度  0---4  默认为1.0
    [lighten setValue:@(0.75) forKey:@"inputContrast"];
    
    CIImage *result = [lighten valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[superImage extent]];
    
    // 得到修改后的图片
    image = [UIImage imageWithCGImage:cgImage];
    
    // 释放对象
    CGImageRelease(cgImage);
    
    return image;
}

- (IBAction)startPreviewAction:(id)sender {
    if (self.viewModel.cameraObj.startPV == true) {
        return;
    }
    
    self.viewModel.cameraObj.startPV = true;
    
    _cameraThumbnail.highlighted = YES;
    _cameraThumbnail.backgroundColor = kSelectedBackgroundColor;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.085 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _cameraThumbnail.highlighted = NO;
        _cameraThumbnail.backgroundColor = kDefaultBackgroundColor;
        
        if ([self.delegate respondsToSelector:@selector(enterPreviewWithCell:)]) {
            [self.delegate enterPreviewWithCell:self];
        }
    });
}

- (IBAction)messageCenterAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(enterMessageCenterWithCell:)]) {
        [self.delegate enterMessageCenterWithCell:self];
    }
}

- (IBAction)localAlbumAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(enterLocalAlbumWithCell:)]) {
        [self.delegate enterLocalAlbumWithCell:self];
    }
}

- (IBAction)shareAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(enterShareWithCell:)]) {
        [self.delegate enterShareWithCell:self];
    }
}

- (IBAction)deleteCameraAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(longPressDeleteCamera:)]) {
        [self.delegate longPressDeleteCamera:self];
    }
}

- (IBAction)changeButtonBackgroundColor:(UIButton *)sender {
//    sender.backgroundColor = kButtonSelectedBackgroundColor;
}

- (IBAction)resetButtonBackgroundColor:(UIButton *)sender {
//    sender.backgroundColor = kButtonDefaultBackgroundColor;
}

#pragma mark - TouchesEvent
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    
    CGPoint p = [t locationInView:self];
    
    if (CGRectContainsPoint(_cameraThumbnail.frame, p)) {
        _cameraThumbnail.highlighted = YES;
        
        _cameraThumbnail.backgroundColor = kSelectedBackgroundColor;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _cameraThumbnail.highlighted = NO;
    
    _cameraThumbnail.backgroundColor = kDefaultBackgroundColor;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _cameraThumbnail.highlighted = NO;
    
    _cameraThumbnail.backgroundColor = kDefaultBackgroundColor;
}

@end
