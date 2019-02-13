// SHWCQRCodeView.m

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
 
 // Created by zj on 2019/1/31 2:18 PM.
    

#import "SHWCQRCodeView.h"
#import "XJLocalAssetHelper.h"

@interface SHWCQRCodeView ()

@property (weak, nonatomic) IBOutlet UIImageView *qrcodeImgView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@end

@implementation SHWCQRCodeView

+ (instancetype)wcqrcodeView {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    SHWCQRCodeView *v = [nib instantiateWithOwner:nil options:nil].firstObject;
    v.frame = [UIScreen mainScreen].bounds;
    
    return v;
}

- (IBAction)saveQRCodeClick:(id)sender {
    [self saveQRCodeHandle];
}

- (void)saveQRCodeHandle {
    NSString *dirPath = [NSString stringWithFormat:@"%@", NSTemporaryDirectory()];
    
    time_t t = time(0);
    struct tm *time1 = localtime(&t);
    NSString *imageName = [NSString stringWithFormat:@"WeChatQRCode-%d%02d%02d_%02d%02d%02d.JPG",  time1->tm_year + 1900,
                           time1->tm_mon + 1, time1->tm_mday, time1->tm_hour, time1->tm_min,
                           time1->tm_sec];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", dirPath, imageName];
    
    [UIImageJPEGRepresentation(self.qrcodeImgView.image, 1.0) writeToFile:filePath atomically:YES];
    
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
    if (fileURL == nil) {
        SHLogWarn(SHLogTagAPP, @"fileURL is nil.");
        return;
    }
    
    [[XJLocalAssetHelper sharedLocalAssetHelper] addNewAssetWithURL:fileURL toAlbum:kLocalAlbumName andFileType:ICH_FILE_TYPE_IMAGE forKey:nil];
    SHLogInfo(SHLogTagAPP, @"Save wechat qrcode finished.");
    
    if ([self.delegate respondsToSelector:@selector(saveQRCodeClicked:)]) {
        [self.delegate saveQRCodeClicked:self];
    }
}

@end
