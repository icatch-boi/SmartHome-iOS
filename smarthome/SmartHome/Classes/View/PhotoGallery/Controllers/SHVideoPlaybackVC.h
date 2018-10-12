//
//  SHVideoPlaybackVC.h
//  SmartHome
//
//  Created by ZJ on 2017/5/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
@class SHVideoPlaybackVC;
@class SHFileTable;

@protocol VideoPlaybackControllerDelegate <NSObject>
- (BOOL)videoPlaybackController:(SHVideoPlaybackVC *)controller
             deleteVideoAtIndex:(NSUInteger)index;
@end

@interface SHVideoPlaybackVC : UIViewController<UIActionSheetDelegate, UIPopoverControllerDelegate, AppDelegateDelegate>
@property (nonatomic, weak) IBOutlet id<VideoPlaybackControllerDelegate> delegate;
@property (nonatomic) UIImage *previewImage;
@property (nonatomic) NSUInteger index;
@property (nonatomic, retain) SHFileTable *curFileTable;
@property (nonatomic, copy) NSString *cameraUid;

//
- (void)updateVideoPbProgress:(double)value;
- (void)updateVideoPbProgressState:(BOOL)caching;
- (void)stopVideoPb;
- (void)showServerStreamError;
@end
