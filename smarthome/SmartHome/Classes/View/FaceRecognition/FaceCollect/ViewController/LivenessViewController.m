//
//  LivenessViewController.m
//  IDLFaceSDKDemoOC
//
//  Created by 阿凡树 on 2017/5/23.
//  Copyright © 2017年 Baidu. All rights reserved.
//

#import "LivenessViewController.h"
#import <IDLFaceSDK/IDLFaceSDK.h>
#import "DisplayViewController.h"
#import "LivingConfigModel.h"


@interface LivenessViewController ()
{
}
@property (nonatomic, strong) NSArray * livenessArray;
@property (nonatomic, assign) BOOL order;
@property (nonatomic, assign) NSInteger numberOfLiveness;
@property (nonatomic, assign) BOOL firstCollect;
@property (nonatomic, strong) UIImage *mainImage;


@end

@implementation LivenessViewController

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (void)viewWillAppear:(BOOL)animated {
    [[IDLFaceLivenessManager sharedInstance] startInitial];
    self.firstCollect = YES;
    LivingConfigModel* model = [LivingConfigModel sharedInstance];
    [[IDLFaceLivenessManager sharedInstance] livenesswithList:model.liveActionArray order:model.isByOrder numberOfLiveness:model.numOfLiveness];
    self.navigationController.navigationBarHidden = true;
    [[IDLFaceDetectionManager sharedInstance] startInitial];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [IDLFaceLivenessManager.sharedInstance reset];
    [IDLFaceDetectionManager.sharedInstance reset];

    self.mainImage = nil;
}

- (void)onAppBecomeActive {
    [super onAppBecomeActive];
    [[IDLFaceLivenessManager sharedInstance] livenesswithList:_livenessArray order:_order numberOfLiveness:_numberOfLiveness];
}

- (void)onAppWillResignAction {
    [super onAppWillResignAction];
    [IDLFaceLivenessManager.sharedInstance reset];
    [IDLFaceDetectionManager.sharedInstance reset];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)livenesswithList:(NSArray *)livenessArray order:(BOOL)order numberOfLiveness:(NSInteger)numberOfLiveness {
    _livenessArray = [NSArray arrayWithArray:livenessArray];
    _order = order;
    _numberOfLiveness = numberOfLiveness;
    [[IDLFaceLivenessManager sharedInstance] livenesswithList:livenessArray order:order numberOfLiveness:numberOfLiveness];
}

- (void)faceProcesss:(UIImage *)image {
    if (self.hasFinished) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    if (self.firstCollect) {
        [self faceDetect:image];
        return;
    }
    
    [[IDLFaceLivenessManager sharedInstance] livenessStratrgyWithImage:image previewRect:self.previewRect detectRect:self.detectRect completionHandler:^(NSDictionary *images, LivenessRemindCode remindCode) {
        switch (remindCode) {
            case LivenessRemindCodeOK: {
                NSLog(@"faceProcesss ok!");
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:images];
                weakSelf.hasFinished = YES;
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kGood", nil)];
                if (images[@"bestImage"] != nil && [images[@"bestImage"] count] != 0) {

                    NSData* data = [[NSData alloc] initWithBase64EncodedString:[images[@"bestImage"] lastObject] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* bestImage = [UIImage imageWithData:data];
                    NSLog(@"bestImage = %@",bestImage);
//                    dict[@"bestImage"] = @[[weakSelf imageFromImage:weakSelf.mainImage inRect:CGRectMake(0, 0, weakSelf.mainImage.size.height, weakSelf.mainImage.size.height * kImageWHScale)]];
                    if (weakSelf.mainImage != nil) {
                        dict[@"bestImage"] = weakSelf.mainImage;
                    }
                } else {
                    if (weakSelf.mainImage != nil) {
                        dict[@"bestImage"] = weakSelf.mainImage;
                    }
                }
                if (images[@"liveEye"] != nil) {
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:images[@"liveEye"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* liveEye = [UIImage imageWithData:data];
                    NSLog(@"liveEye = %@",liveEye);
                }
                if (images[@"liveMouth"] != nil) {
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:images[@"liveMouth"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* liveMouth = [UIImage imageWithData:data];
                    NSLog(@"liveMouth = %@",liveMouth);
                }
                if (images[@"yawRight"] != nil) {
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:images[@"yawRight"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* yawRight = [UIImage imageWithData:data];
                    NSLog(@"yawRight = %@",yawRight);
                    if (yawRight != nil) {
                        dict[@"yawRight"] = yawRight;
                    }
                }
                if (images[@"yawLeft"] != nil) {
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:images[@"yawLeft"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* yawLeft = [UIImage imageWithData:data];
                    NSLog(@"yawLeft = %@",yawLeft);
                    if (yawLeft != nil) {
                        dict[@"yawLeft"] = yawLeft;
                    }
                }
                if (images[@"pitchUp"] != nil) {
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:images[@"pitchUp"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* pitchUp = [UIImage imageWithData:data];
                    NSLog(@"pitchUp = %@",pitchUp);
                    if (pitchUp != nil) {
                        dict[@"pitchUp"] = pitchUp;
                    }
                }
                if (images[@"pitchDown"] != nil) {
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:images[@"pitchDown"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* pitchDown = [UIImage imageWithData:data];
                    NSLog(@"pitchDown = %@",pitchDown);
                    if (pitchDown != nil) {
                        dict[@"pitchDown"] = pitchDown;
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
//                    [weakSelf closeAction];
                    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"FaceCollect" bundle:nil];
                    UINavigationController *nav = (UINavigationController *)[sb instantiateViewControllerWithIdentifier:@"DisplayViewControllerID"];
                    DisplayViewController *vc = (DisplayViewController *)nav.topViewController;
                    vc.images = dict.copy;
//                    [self presentViewController:nav animated:YES completion:nil];
                    [self.navigationController pushViewController:vc animated:YES];
                });
                self.circleView.conditionStatusFit = true;
                [self singleActionSuccess:true];
                break;
            }
            case LivenessRemindCodePitchOutofDownRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kRaiseSlightly", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodePitchOutofUpRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kBowSlightly", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeYawOutofLeftRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kSlightlyToTheRight", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeYawOutofRightRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kSlightlyToTheLeft", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodePoorIllumination:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kLightAgain", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeNoFaceDetected:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kMoveIntoTheBox", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeImageBlured:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kPleaseStayStill", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeOcclusionLeftEye:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kLeftEyeHasOcclusion", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeOcclusionRightEye:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kRightEyeHasOcclusion", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeOcclusionNose:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kNoisyNose", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeOcclusionMouth:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kMouthBlocked", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeOcclusionLeftContour:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kLeftCheekHasOcclusion", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeOcclusionRightContour:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kRightCheekHasOcclusion", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeOcclusionChinCoutour:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kLowerJawHasOcclusion", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeTooClose:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kTakeLonger", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeTooFar:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kTakeCloser", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeBeyondPreviewFrame:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kMoveIntoTheBox", nil) conditionMeet:false];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeLiveEye:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kBlink", nil) conditionMeet:true];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeLiveMouth:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kOpenMouth", nil) conditionMeet:true];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeLiveYawRight:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kHeadSlowlyRight", nil) conditionMeet:true];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeLiveYawLeft:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kHeadSlowlyLeft", nil) conditionMeet:true];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeLivePitchUp:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kSlowlyLookingup", nil) conditionMeet:true];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeLivePitchDown:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kSlowlybowing", nil) conditionMeet:true];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeLiveYaw:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kShakingHisHead", nil) conditionMeet:true];
                [self singleActionSuccess:false];
                break;
            case LivenessRemindCodeSingleLivenessFinished:
            {
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kGood", nil) conditionMeet:true];
                [self singleActionSuccess:true];
            }
                break;
            case LivenessRemindCodeVerifyInitError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeVerifyDecryptError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeVerifyInfoFormatError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeVerifyExpired:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeVerifyMissRequiredInfo:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeVerifyInfoCheckError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeVerifyLocalFileError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeVerifyRemoteDataError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case LivenessRemindCodeTimeout: {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"ActionTimeOut", nil) preferredStyle:UIAlertControllerStyleAlert];
//                    UIAlertAction* action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                        NSLog(@"知道啦");
//                    }];
//                    [alert addAction:action];
//                    UIViewController* fatherViewController = weakSelf.presentingViewController;
//                    [weakSelf dismissViewControllerAnimated:YES completion:^{
//                        [fatherViewController presentViewController:alert animated:YES completion:nil];
//                    }];
//                });
                NSLog(@"超时啦 %d", __LINE__);
                break;
            }
            case LivenessRemindCodeConditionMeet: {
                self.circleView.conditionStatusFit = true;
            }
                break;
            default:
                break;
        }
    }];
}

- (void)faceDetect:(UIImage *)image {
    __weak typeof(self) weakSelf = self;

    [[IDLFaceDetectionManager sharedInstance] detectStratrgyWithNormalImage:image previewRect:self.previewRect detectRect:self.detectRect completionHandler:^(FaceInfo *faceinfo, NSDictionary *images, DetectRemindCode remindCode) {
        switch (remindCode) {
            case DetectRemindCodeOK: {
                //                    weakSelf.hasFinished = YES;
                NSLog(@"faceDetect ok!");
                self.firstCollect = NO;
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kGood", nil)];
                [self singleActionSuccess:true];
                if (images[@"bestImage"] != nil && [images[@"bestImage"] count] != 0) {
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:[images[@"bestImage"] lastObject] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* bestImage = [UIImage imageWithData:data];
                    NSLog(@"**** bestImage = %@",bestImage);
                    weakSelf.mainImage = bestImage;
                }

                break;
            }
                
            case DetectRemindCodePitchOutofDownRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kRaiseSlightly", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodePitchOutofUpRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kBowSlightly", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeYawOutofLeftRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kSlightlyToTheRight", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeYawOutofRightRange:
                [self warningStatus:PoseStatus warning:NSLocalizedString(@"kSlightlyToTheLeft", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodePoorIllumination:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kLightAgain", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeNoFaceDetected:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kMoveIntoTheBox", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeImageBlured:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kPleaseStayStill", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeOcclusionLeftEye:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kLeftEyeHasOcclusion", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeOcclusionRightEye:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kRightEyeHasOcclusion", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeOcclusionNose:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kNoisyNose", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeOcclusionMouth:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kMouthBlocked", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeOcclusionLeftContour:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kLeftCheekHasOcclusion", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeOcclusionRightContour:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kRightCheekHasOcclusion", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeOcclusionChinCoutour:
                [self warningStatus:occlusionStatus warning:NSLocalizedString(@"kLowerJawHasOcclusion", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeTooClose:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kTakeLonger", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeTooFar:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kTakeCloser", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeBeyondPreviewFrame:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kMoveIntoTheBox", nil)];
                [self singleActionSuccess:false];
                break;
            case DetectRemindCodeVerifyInitError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeVerifyDecryptError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeVerifyInfoFormatError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeVerifyExpired:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeVerifyMissRequiredInfo:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeVerifyInfoCheckError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeVerifyLocalFileError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeVerifyRemoteDataError:
                [self warningStatus:CommonStatus warning:NSLocalizedString(@"kVerificationFailed", nil)];
                break;
            case DetectRemindCodeTimeout: {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"remind" message:@"超时" preferredStyle:UIAlertControllerStyleAlert];
//                    UIAlertAction* action = [UIAlertAction actionWithTitle:@"知道啦" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                        NSLog(@"知道啦 %d", __LINE__);
//                    }];
//                    [alert addAction:action];
//                    UIViewController* fatherViewController = weakSelf.presentingViewController;
//                    [weakSelf dismissViewControllerAnimated:YES completion:^{
//                        [fatherViewController presentViewController:alert animated:YES completion:nil];
//                    }];
//                });
                NSLog(@"超时啦 %d", __LINE__);
                break;
            }
            case DetectRemindCodeConditionMeet: {
                self.circleView.conditionStatusFit = true;
            }
                break;
            default:
                break;
        }
    }];
}

- (void)warningStatus:(WarningStatus)status warning:(NSString *)warning conditionMeet:(BOOL)meet
{
    [self warningStatus:status warning:warning];
    self.circleView.conditionStatusFit = meet;
}

- (void)dealloc
{
    
}
@end
