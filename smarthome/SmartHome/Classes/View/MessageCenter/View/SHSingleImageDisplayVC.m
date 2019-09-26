// SHSingleImageDisplayVC.m

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
 
 // Created by zj on 2019/8/20 10:28 AM.
    

#import "SHSingleImageDisplayVC.h"
#import "SHMessageInfo.h"
#import "SVProgressHUD.h"
#import "UIImageView+ZJWebCache.h"

@interface SHSingleImageDisplayVC ()

@property (weak, nonatomic) IBOutlet UIImageView *bigImageView;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (nonatomic, strong) SHMessageInfo *messageInfo;

@end

@implementation SHSingleImageDisplayVC

+ (instancetype)singleImageDisplayVCWithMessageInfo:(SHMessageInfo *)messageInfo {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kMessageCenterStoryboardName bundle:nil];
    SHSingleImageDisplayVC *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    
    vc.messageInfo = messageInfo;
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    [self displayBigImage];
}

- (void)setupGUI {
    self.navigationItem.rightBarButtonItem = nil;
    
    self.title = _messageInfo.message.msgTypeString;
    _detailLabel.text = _messageInfo.localTimeString;
}

- (void)setupRightBarButtonItem {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(moreActionClick:)];
}

- (void)displayBigImage {
    _bigImageView.image = [UIImage imageNamed:@"empty_photo"];
    
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    WEAK_SELF(self);
    [_messageInfo getMessageFileWithCompletion:^(UIImage * _Nullable image) {
        [SVProgressHUD dismiss];
#ifndef KUSE_S3_SERVICE
#if 0
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.bigImageView.image = image;
                
                [weakself setupRightBarButtonItem];
            });
        }
#else
        [weakself.bigImageView setImageURLString:weakself.messageInfo.messageFile.url cacheKey:weakself.messageInfo.fileIdentifier];
#endif
#else
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.bigImageView.image = image;
                
                [weakself setupRightBarButtonItem];
            });
        }
#endif
    }];
}

- (void)moreActionClick:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:@[self.bigImageView.image] applicationActivities:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:activityVC animated:YES completion:nil];
    } else {
        // Create pop up
        UIPopoverController *activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityVC];
        // Show UIActivityViewController in popup
        //            UIBarButtonItem *btnItem = [[UIBarButtonItem alloc] initWithCustomView:sender];
        [activityPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

@end
