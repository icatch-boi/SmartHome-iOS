// SHAccountInfoHeaderView.m

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
 
 // Created by zj on 2018/5/3 上午10:42.
    

#import "SHAccountInfoHeaderView.h"
#import "SDWebImageManager.h"

static const CGFloat kNickNameLabelMargin = 20;
static const CGFloat kNickNameLabelMinFontSize = 20;

@interface SHAccountInfoHeaderView ()

@property (weak, nonatomic) IBOutlet UIButton *avatorButton;
@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;

@end

@implementation SHAccountInfoHeaderView

+ (instancetype)accountInfoHeaderViewWithFrame:(CGRect)rect {
    UINib *nib = [UINib nibWithNibName:@"SHAccountInfoHeaderView" bundle:nil];
    SHAccountInfoHeaderView *view = [nib instantiateWithOwner:nil options:nil].firstObject;
    view.frame = rect;
    view.nickNameLabel.numberOfLines = 1;
    
#if 0
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[UIColor ic_colorWithRed:77 green:171 blue:244 alpha:1.0].CGColor, (__bridge id)[UIColor ic_colorWithRed:57 green:100 blue:225 alpha:1.0].CGColor];
    
//    gradientLayer.locations = @[@0.3, @0.5, @1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1.0);
    gradientLayer.frame = rect;
//    [view.layer addSublayer:gradientLayer];
    [view.layer insertSublayer:gradientLayer below:view.layer.superlayer];
#endif
    view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"leftbar"]];
    
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [_avatorButton setCornerWithRadius:_avatorButton.bounds.size.width * 0.5 masksToBounds:YES];
}

- (void)setGradientColor {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor yellowColor].CGColor, (__bridge id)[UIColor blueColor].CGColor];
    gradientLayer.locations = @[@0.3, @0.5, @1.0];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1.0);
    gradientLayer.frame = self.frame;
    [self.layer addSublayer:gradientLayer];
}

- (void)setNickName:(NSString *)nickName {
    _nickName = nickName;
    _nickNameLabel.text = [self repairNickName:nickName];

    [self adjustNickNameLabelFontSize];
}

- (void)adjustNickNameLabelFontSize {
    CGFloat width = CGRectGetWidth(self.frame) - 2 * kNickNameLabelMargin;
    
    CGFloat fontSize = _nickNameLabel.font.pointSize;
    CGFloat realWidth = [self calcNickNameLabelRealWidthWithFontSize:fontSize];
    
    while (fontSize > kNickNameLabelMinFontSize && realWidth > width) {
        fontSize--;
        realWidth = [self calcNickNameLabelRealWidthWithFontSize:fontSize];
    }
    
    SHLogInfo(SHLogTagAPP, @"font size: %f, label real width: %f", fontSize, realWidth);
    _nickNameLabel.font = [UIFont systemFontOfSize:fontSize];
}

- (CGFloat)calcNickNameLabelRealWidthWithFontSize:(CGFloat)fontSize {
    return [_nickNameLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]} context:nil].size.width;
}

- (NSString *)repairNickName:(NSString *)nickName {
    if ([nickName containsString:@"@"]) {
        NSRange range = [nickName rangeOfString:@"@"];
        nickName = [nickName substringToIndex:range.location];
    }
    
    return nickName;
}

- (void)setAvatorName:(NSString *)avatorName {
    _avatorName = avatorName;
    
#if 0
    NSString *avatorPath = [BASE_URL_TEST stringByAppendingPathComponent:avatorName]; //@"http://upload.univs.cn/2012/0104/1325645511371.jpg"
    NSURL *avatorURL = [NSURL URLWithString:avatorPath];
    
    UIImage *placeholderImage = [UIImage imageNamed:@"portrait-1"];
    UIImage *placeholderImage_Avator = [placeholderImage ic_avatarImageWithSize:placeholderImage.size backColor:self.backgroundColor lineColor:[UIColor lightGrayColor] lineWidth:1.0];
    
    [self setUserAvatorWithURL:avatorURL placeholderImage:placeholderImage_Avator];
#endif
    
    [self setAvatorImage:[UIImage imageNamed:@"leftbar-user"]];
}

- (void)setUserAvatorWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self setAvatorImage:placeholder];
    
    WEAK_SELF(self);
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                UIImage *tempImage = [image ic_avatarImageWithSize:image.size backColor:weakself.backgroundColor lineColor:[UIColor lightGrayColor] lineWidth:1.0];
                [weakself setAvatorImage:tempImage];

                [weakself.avatorButton setNeedsLayout];
            }
        });
    }];
//    [[SDWebImageManager sharedManager] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (image) {
//                UIImage *tempImage = [image ic_avatarImageWithSize:image.size backColor:weakself.backgroundColor lineColor:[UIColor lightGrayColor] lineWidth:1.0];
//                [weakself setAvatorImage:tempImage];
//
//                [weakself.avatorButton setNeedsLayout];
//            }
//        });
//    }];
}

- (void)setAvatorImage:(UIImage *)image {
    [_avatorButton setImage:image forState:UIControlStateNormal];
    [_avatorButton setImage:image forState:UIControlStateHighlighted];
}

- (IBAction)enterAccountAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(enterAccountWithHeaderView:)]) {
        [self.delegate enterAccountWithHeaderView:self];
    }
}

//- (void)setAvatorImage:(UIImage *)avatorImage {
//    _avatorImage = avatorImage;
//    _avatorImgView.image = [avatorImage ic_avatarImageWithSize:avatorImage.size backColor:self.backgroundColor lineColor:[UIColor lightGrayColor] lineWidth:1.0];
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
