// FaceCollectionViewCell.m

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
 
 // Created by zj on 2019/1/4 3:21 PM.
    

#import "FaceCollectionViewCell.h"
#import "FRDFaceData.h"

@interface FaceCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *faceImgView;
@property (weak, nonatomic) IBOutlet UIButton *opertionButton;

@end

@implementation FaceCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupGUI];
}

- (void)setupGUI {
    self.backgroundColor = [UIColor ic_colorWithHex:0xf2f2f2];
    [self.opertionButton setCornerWithRadius:CGRectGetHeight(self.opertionButton.bounds) * 0.2 masksToBounds:NO];
    [self.opertionButton setBorderWidth:1.0 borderColor:[UIColor ic_colorWithHex:kButtonThemeColor]];
    [self.opertionButton setTitleColor:[UIColor ic_colorWithHex:kButtonThemeColor] forState:UIControlStateNormal];
    [self.opertionButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
}

- (IBAction)addFaceClick:(id)sender {
    SHLogTRACE();
    if ([self.delegate respondsToSelector:@selector(opertionClickWithFaceCollectionViewCell:)]) {
        [self.delegate opertionClickWithFaceCollectionViewCell:self];
    }
}

- (void)setFaceData:(FRDFaceData *)faceData {
    _faceData = faceData;
    
    _faceImgView.image = faceData.faceImage;
    [_opertionButton setTitle:faceData.title forState:UIControlStateNormal];
    _opertionButton.enabled = !faceData.alreadyAdd;
}

@end
