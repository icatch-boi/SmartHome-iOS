//
//  SHMessageAlertView.m
//  SmartHome
//
//  Created by ZJ on 2017/6/7.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHMessageAlertView.h"
#import "SHMessage.h"

@interface SHMessageAlertView ()

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@end

@implementation SHMessageAlertView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (instancetype)messageAlertViewWithController:(UIViewController *)vc message:(SHMessage *)msg cameras:(NSArray *)cameras {
    SHMessageAlertView *messageAlertView = [[[NSBundle mainBundle] loadNibNamed:@"SHMessageAlertView" owner:nil options:nil] firstObject];
    
    messageAlertView.frame = CGRectMake(0, kHeight - kAlertViewWidth, kWidth, kAlertViewWidth);
//    messageAlertView.layer.cornerRadius = 10;
//    messageAlertView.layer.masksToBounds = YES;
    [messageAlertView setCornerWithRadius:10];
    
    messageAlertView.messageLabel.text = [self splitMessageStr:msg cameras:cameras];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [messageAlertView addGestureRecognizer:pan];
    
    [vc.navigationController.view addSubview:messageAlertView];
    
    return messageAlertView;
}

+ (void)pan:(UIPanGestureRecognizer *)sender {
    CGPoint p = [sender translationInView:sender.view];
    
    [UIView animateWithDuration:0.25 animations:^{
        sender.view.transform = CGAffineTransformTranslate(sender.view.transform, p.x, 0);
    } completion:^(BOOL finished) {
        if (abs((int)p.x) > kAlertViewWidth) {
            [sender.view removeFromSuperview];
        } else {
            [UIView animateWithDuration:0.25 animations:^{
                sender.view.frame = CGRectMake(0, kHeight - kAlertViewWidth, kWidth, kAlertViewWidth);
            }];
        }
    }];
    
    //恢复到初始状态
//    [sender setTranslation:CGPointZero inView:sender.view];
}

+ (NSString *)splitMessageStr:(SHMessage *)msg cameras:(NSArray *)cameras {
    NSString *str = nil;
    NSString *cameraName = [self prepareCameraName:msg cameras:cameras];
    
    switch (msg.msgType) {
        case PushMessageTypePir:
            str = @"PIR";
            break;
            
        case PushMessageTypeLowPower:
            str = @"LowPower";
            break;
            
        case PushMessageTypeSDCardFull:
            str = @"SDCardFull";
            break;
            
        case PushMessageTypeSDCardError:
            str = @"SDCardError";
            break;
            
        case PushMessageTypeRing:
            str = @"Ring";
            break;
            
        case PushMessageTypeFDHit:
            str = @"FD Hit";
            break;
            
        case PushMessageTypeFDMiss:
            str = @"FD Miss";
            break;
            
        case PushMessageTypePushTest:
            str = @"PushTest";
            break;
            
        case PushMessageTypeTamperAlarm:
            str = @"Demolish";
            break;
            
        default:
            str = @"unknown";
            break;
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"kpushMessageTipsInfo", nil), (cameraName ? cameraName : @"Camera"), str, msg.time];
}

+ (NSString *)prepareCameraName:(SHMessage *)msg cameras:(NSArray *)cameras {
    __block NSString *cameraName = nil;
    
    [cameras enumerateObjectsUsingBlock:^(SHCameraObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.camera.cameraUid isEqualToString:msg.devID]) {
            cameraName = obj.camera.cameraName;
            *stop = YES;
        }
    }];
    
    return cameraName;
}

@end
