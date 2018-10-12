//
//  SHShareCameraViewController.h
//  SmartHome
//
//  Created by 莊志銘 on 2017/11/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
@interface SHShareCameraViewController : UIViewController<MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *uidlabel;
@property (weak, nonatomic) IBOutlet UITextField *shareEmail;
- (IBAction)doShare:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *qrImage;
@property (nonatomic, strong) SHCamera *camera;
@end
