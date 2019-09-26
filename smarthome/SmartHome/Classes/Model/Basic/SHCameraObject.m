//
//  SHCam.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHCameraObject.h"
#import "SHSDKEventListener.hpp"
#import "SHObserver.h"
#import "SHDownloadManager.h"
#import "SHNetworkManager.h"
#import "SHNetworkManager+SHCamera.h"
#import "SHMessageCountManager.h"

#define kChannelsPerFrame   1
#define kBitsPerChannel     16

@interface SHCameraObject ()

@property (nonatomic) SHObserver *batteryLevelObserver;
@property (nonatomic) SHObserver *sdCardObserver;
@property (nonatomic) SHObserver *fileAddedObserver;
@property (nonatomic) SHObserver *disconnectObserver;
@property (nonatomic) SHObserver *powerOffObserver;
@property (nonatomic, strong) SHObserver *bitRateObserver;
@property (nonatomic, strong) SHObserver *chargeStatusObserver;
@property (nonatomic, strong) SHObserver *packageDownloadSizeObserver;
@property (nonatomic, strong) SHObserver *clientCountObserver;
@property (nonatomic, strong) SHObserver *noTalkingObserver;
@property (nonatomic, strong) SHObserver *recvVideoTimeoutObserver;
@property (nonatomic, assign) NSUInteger newMessageCount;

@end

@implementation SHCameraObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)cameraObjectWithCamera:(SHCamera *)camera {
	SHCameraObject *obj = [[self alloc] init];
	
	obj.controler = [self createControlCenter];
	obj.gallery = [[SHPhotoGallery alloc] init];
	obj.cameraProperty = [[SHCameraProperty alloc] init];
	obj.camera = camera;
    obj.streamQuality = VIDEO_QUALITY_SMOOTH;
    obj.sdk = [[SHSDK alloc] init];
    obj.newMessageCount = 0;

	return obj;
}

+ (SHControlCenter *)createControlCenter
{
	SHCommonControl *comCtrl = [[SHCommonControl alloc] init];
	SHPropertyControl *propCtrl = [[SHPropertyControl alloc] init];
	SHActionControl *actCtrl = [[SHActionControl alloc] init];
	SHFileControl *fileCtrl = [[SHFileControl alloc] init];
	SHPlaybackControl *pbCtrl = [[SHPlaybackControl alloc] init];
	SHControlCenter *ctrl = [[SHControlCenter alloc] initWithParameters:comCtrl
													 andPropertyControl:propCtrl
													   andActionControl:actCtrl
														 andFileControl:fileCtrl
													 andPlaybackControl:pbCtrl];
	return ctrl;
}

- (dispatch_semaphore_t)semaphore {
	if (!_semaphore) {
		_semaphore = dispatch_semaphore_create(1);
	}
	
	return _semaphore;
}

- (SHPropertyQueryResult *)curResult {
	if (!_curResult) {
		_curResult = [self.controler.propCtrl retrievePVCurPropertyWithCamera:self];
	}
	
	return _curResult;
}

- (void)updatePreviewThumbnail {
	NSString *tempPVTime = [self.controler.propCtrl retrieveLastPreviewTimeWithCamera:self curResult:self.curResult];
	SHLogInfo(SHLogTagAPP, @"tempPVTime is : %@",tempPVTime);

	if (![tempPVTime isEqualToString:_camera.pvTime] || _camera.pvTime == nil) {
		self.camera.pvTime = tempPVTime;
		
		UIImage *thumbnail = [self.controler.propCtrl retrievePreviewThumbanilWithCamera:self curResult:self.curResult];
		if (thumbnail) {
			self.camera.thumbnail = thumbnail;
            NSData *imgData = UIImageJPEGRepresentation(thumbnail, 0.5);
            //上传到服务器 add by j.chen
            [[SHNetworkManager sharedNetworkManager] updateCameraCoverByCameraID:self.camera.id andCoverData:imgData completion:^(BOOL isSuccess, id  _Nonnull result) {
                if(isSuccess) {
                    SHLogInfo(SHLogTagAPP, @"update thumnail success");
                } else {
                    SHLogError(SHLogTagAPP, @"update thumnail fail");
                }
            }];
		}
		
		// Save data to sqlite
		NSError *error = nil;
		if (![self.camera.managedObjectContext save:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
		} else {
			SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
		}
	}
	
	_newFilesCount = [self.controler.propCtrl retrieveNewFilesCountWithCamera:self pbTime:_camera.pbTime];
}

- (void)updatePreviewThumbnailWithPvTime: (NSString *)tempPVTime {
	SHLogInfo(SHLogTagAPP, @"tempPVTime is : %@",tempPVTime);
    
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
    if ((dispatch_semaphore_wait(self.semaphore, time) != 0)) {
        SHLogError(SHLogTagAPP, @"time out");
    } else {
        if (![tempPVTime isEqualToString:_camera.pvTime] || _camera.pvTime == nil) {
            self.camera.pvTime = tempPVTime;
            
            UIImage *thumbnail = [self.controler.propCtrl retrievePreviewThumbanilWithCamera:self curResult:self.curResult];
            if (thumbnail) {
                self.camera.thumbnail = thumbnail;
                NSData *coverData = UIImageJPEGRepresentation(thumbnail, 0.5);
                [[SHNetworkManager sharedNetworkManager] updateCameraCoverByCameraID:self.camera.id andCoverData:coverData completion:^(BOOL isSuccess, id  _Nonnull result) {
                    if(isSuccess) {
                        SHLogInfo(SHLogTagAPP, @"update device cover success");
                    } else {
                        SHLogError(SHLogTagAPP, @"update device cover failure");
                    }
                }];
            }
            
            // Save data to sqlite
            NSError *error = nil;
            if (![self.camera.managedObjectContext save:&error]) {
                /*
                 Replace this implementation with code to handle the error appropriately.
                 
                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                 */
                SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                abort();
#endif
            } else {
                SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
            }
        }
        
        dispatch_semaphore_signal(self.semaphore);
    }
}


- (void)connectWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock {
	SHSDK *sdk = [[SHSDK alloc] init];
	
	dispatch_async([sdk sdkQueue], ^{
		int totalCheckCount = 2;
		while (totalCheckCount-- > 0) {
			SHLogInfo(SHLogTagAPP, @" to connect camera,camera name is : %@",self.camera.cameraName);
			if ([sdk initializeSHSDK:self.camera.cameraUid devicePassword:self.camera.devicePassword] == ICH_SUCCEED) {
				
				self.streamOper = [[SHStreamOperate alloc] initWithCameraObject:self];
				self.controler.actCtrl.shCamObj = self;
				self.controler.fileCtrl.shCamObj = self;
				self.gallery.shCamObj = self;
				self.sdk = sdk;
//				self.cameraProperty = [[SHCameraProperty alloc] init];
//				self.cameraProperty.previewMode = SHPreviewModeVideoOff | SHPreviewModeCameraOff | SHPreviewModeTalkBackOff;
				[self.cameraProperty cleanCurrentCameraAllProperty];
				
				if ([sdk isSHSDKInitialized]) {
					self.isConnect = YES;
					[self addCameraPropertyObserver];
					[self updatePreviewThumbnail];
					if (successBlock) {
						successBlock();
					}
				} else {
					continue;
				}
				
				return;
			}
			//
			SHLogInfo(SHLogTagAPP, @"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
			[NSThread sleepForTimeInterval:0.5];
			
			if (totalCheckCount <= 0) {
				if (failedBlock) {
					failedBlock();
				}
			}
		}
	});
}

- (int)connectCamera {
    SHLogTRACE();
//    SHSDK *sdk = [[SHSDK alloc] init];
	int retValue = ICH_SUCCEED;
	//dispatch_async([sdk sdkQueue], ^{
		SHLogInfo(SHLogTagAPP, @" to connect camera,camera name is : %@",self.camera.cameraName);
    if (self.isConnect == true) {
        SHLogWarn(SHLogTagAPP, @"The device already connect.");
        return ICH_SUCCEED;
    }
    if (self.camera == nil || self.camera.cameraUid == nil) {
        SHLogError(SHLogTagAPP, @"camera or camera uid is nil.");

        return ICH_TUTK_IOTC_CONNECTION_UNKNOWN_ER;
    }
        if ((retValue = [self.sdk initializeSHSDK:self.camera.cameraUid devicePassword:self.camera.devicePassword]) == ICH_SUCCEED) {
            
            self.streamOper = [[SHStreamOperate alloc] initWithCameraObject:self];
            self.controler.actCtrl.shCamObj = self;
            self.controler.fileCtrl.shCamObj = self;
            self.gallery.shCamObj = self;
//            self.sdk = sdk;
            self.cameraProperty.previewMode = 0;
            
            if ([self.sdk isSHSDKInitialized]) {
                self.isConnect = YES;
                [self addCameraPropertyObserver];
            } else {
                
            }
        } else {
            self.startPV = NO;
        }
    
	return retValue;
}

- (void)initCamera {
    [self checkIsMapToTutk];
}

- (void)checkIsMapToTutk {
    if (!self.camera.mapToTutk) {
        [SHTutkHttp registerDevice:self.camera];
    }
}

- (void)cleanCamera {
    self.isConnect = NO;
    self.startPV = NO;
    self.cameraProperty.serverOpened = NO;
    
    [self.cameraProperty cleanCacheFormat];
    [self.cameraProperty cleanCacheData];
    [self.cameraProperty cleanCurrentCameraAllProperty];
    
    _curResult = nil;
//    _sdk = nil;
    _streamOper = nil;
    
    [self.gallery cleanDateInfo];
    [self.cameraProperty updateSDCardInfo:self];
}

- (void)openAudioServer {
    SHLogTRACE();
    if (self.cameraProperty.serverOpened) {
        SHLogInfo(SHLogTagAPP, @"Audio server already opened.");
        return;
    }
   
    ICatchAudioFormat *audioFormat = new ICatchAudioFormat();
    NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
    int audioRate = (int)[defaultSettings integerForKey:@"PreferenceSpecifier:audioRate"];
    audioFormat->setCodec(ICATCH_CODEC_MPEG4_GENERIC);
    audioFormat->setFrequency(audioRate);
    audioFormat->setSampleBits(kBitsPerChannel);
    audioFormat->setNChannels(kChannelsPerFrame);
    
    if ([_sdk openAudioServer:*audioFormat]) {
        self.cameraProperty.serverOpened = YES;
    } else {
        self.cameraProperty.serverOpened = NO;
    }
}

- (void)disConnectWithSuccessBlock:(void(^)())successBlock failedBlock:(void(^)())failedBlock {
    SHLogTRACE();
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		
		dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
		if ((dispatch_semaphore_wait(self.semaphore, time) != 0)) {
            SHLogError(SHLogTagAPP, @"Disconnect timeout!");
            
            dispatch_semaphore_signal(self.semaphore);
            
            [self disconnectHandle];
            
			if (failedBlock) {
				failedBlock();
			}
		} else {
            dispatch_semaphore_signal(self.semaphore);
        
            [self disconnectHandle];

            if (successBlock) {
                successBlock();
            }
		}
//    });
}

- (void)disconnectHandle {
//    [self.sdk disableTutk];
    
    if (self.streamOper.PVRun) {
        [self.streamOper stopMediaStreamWithComplete:nil];
    }
    
    [self.controler.pbCtrl stopWithCamera:self];
    
    [self removeCameraPropertyObserver];
    //delete download list before disconnect
    [[SHDownloadManager shareDownloadManger] clearDownloadingByUid:self.camera.cameraUid];
    [self.sdk destroySHSDK];
    [self.streamOper uploadPreviewThumbnailToServer];
    [self cleanCamera];
}

#pragma mark - Observer
- (void)addCameraPropertyObserver {
	SHSDKEventListener *batteryLevelListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.batteryLevelObserver = [SHObserver cameraObserverWithListener:batteryLevelListener eventType:ICATCH_EVENT_BATTERY_LEVEL_CHANGED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.batteryLevelObserver];

	SHSDKEventListener *sdCardListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.sdCardObserver = [SHObserver cameraObserverWithListener:sdCardListener eventType:ICATCH_EVENT_SDCARD_INFO_CHANGED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.sdCardObserver];

	SHSDKEventListener *fileAddedListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.fileAddedObserver = [SHObserver cameraObserverWithListener:fileAddedListener eventType:ICATCH_EVENT_FILE_ADDED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.fileAddedObserver];

    SHSDKEventListener *disconnectListener = new SHSDKEventListener(self, @selector(notifyDisconnectionEvent));
    self.disconnectObserver = [SHObserver cameraObserverWithListener:disconnectListener eventType:ICATCH_EVENT_CONNECTION_DISCONNECTED isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.disconnectObserver];
    
    SHSDKEventListener *powerOffListener = new SHSDKEventListener(self, @selector(notifyCameraPowerOffEvent:));
    self.powerOffObserver = [SHObserver cameraObserverWithListener:powerOffListener eventType:ICATCH_EVENT_CAMERA_POWER_OFF isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.powerOffObserver];
    
    [self addVideoBitRateObserver];
    
    SHSDKEventListener *chargeStatusListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
    self.chargeStatusObserver = [SHObserver cameraObserverWithListener:chargeStatusListener eventType:ICATCH_EVENT_CHARGE_STATUS_CHANGED isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.chargeStatusObserver];
    
    SHSDKEventListener *packagedownloadSizeListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
    self.packageDownloadSizeObserver = [SHObserver cameraObserverWithListener:packagedownloadSizeListener eventType:ICATCH_EVENT_UPGRADE_PACKAGE_DOWNLOADED_SIZE isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.packageDownloadSizeObserver];
    
    SHSDKEventListener *clientCountListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
    self.clientCountObserver = [SHObserver cameraObserverWithListener:clientCountListener eventType:ICATCH_EVENT_CONNECTION_CLIENT_COUNT isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.clientCountObserver];
    
    SHSDKEventListener *noTalkingListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
    self.noTalkingObserver = [SHObserver cameraObserverWithListener:noTalkingListener eventType:ICATCH_EVENT_NO_TALKING isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.noTalkingObserver];
    
    SHSDKEventListener *recvDataTimeoutListener = new SHSDKEventListener(self, @selector(notifyRecvVideoTimeoutEvent));
    self.recvVideoTimeoutObserver = [SHObserver cameraObserverWithListener:recvDataTimeoutListener eventType:ICATCH_EVENT_RECEIVE_VIDEO_TIMEOUT isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.recvVideoTimeoutObserver];
}

- (void)cameraPropertyValueChangeCallback:(SHICatchEvent *)evt {
//    SHLogInfo(SHLogTagAPP, @"receive event: %@", evt);
    
    switch (evt.eventID) {
        case ICATCH_EVENT_FILE_ADDED:
            SHLogInfo(SHLogTagAPP, @"receive ICATCH_EVENT_FILE_ADDED");
            [self.gallery cleanDateInfo];
            [self.cameraProperty updateSDCardInfo:self];
            break;
            
        case ICATCH_EVENT_SDCARD_INFO_CHANGED:
            self.cameraProperty.SDUseableSize = evt.intValue1;
            
            if (evt.intValue1 == -1) {
                self.cameraProperty.memorySizeData = nil;
            }
            break;
            
        case ICATCH_EVENT_CONNECTION_CLIENT_COUNT:
            if (self.cameraProperty.clientCount == 0) {
                self.cameraProperty.noTalking = evt.intValue1 > 1 ? 1 : 0;
            } else {
                if (evt.intValue1 == 1) {
                    self.cameraProperty.noTalking = 0;
                }
            }
            self.cameraProperty.clientCount = evt.intValue1;
            break;
            
        case ICATCH_EVENT_NO_TALKING:
            SHLogInfo(SHLogTagAPP, @"No talking state: %d", evt.intValue1);
            self.cameraProperty.noTalking = evt.intValue1;
            break;
            
        default:
            break;
    }
    
    if (self.cameraPropertyValueChangeBlock) {
        self.cameraPropertyValueChangeBlock(evt);
    }
}

- (void)notifyDisconnectionEvent {
    SHLogTRACE();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kCameraDisconnectNotification object:self];
    });
}

- (void)notifyCameraPowerOffEvent:(SHICatchEvent *)evt {
    SHLogTRACE();
    int intValue1 = evt.intValue1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kCameraPowerOffNotification object:self userInfo:@{kPowerOffEventValue: @(intValue1)}];
    });
}

- (void)notifyRecvVideoTimeoutEvent {
    SHLogTRACE();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kRecvVideoTimeoutNotification object:self];
    });
}

- (void)removeCameraPropertyObserver {
	if (self.batteryLevelObserver) {
		[self.sdk removeObserver:self.batteryLevelObserver];
		
		if (self.batteryLevelObserver.listener) {
			delete self.batteryLevelObserver.listener;
			self.batteryLevelObserver.listener = NULL;
		}
		
		self.batteryLevelObserver = nil;
	}
	
	if (self.sdCardObserver) {
		[self.sdk removeObserver:self.sdCardObserver];
		
		if (self.sdCardObserver.listener) {
			delete self.sdCardObserver.listener;
			self.sdCardObserver.listener = NULL;
		}
		
		self.sdCardObserver = nil;
	}
    
    if (self.fileAddedObserver) {
        [self.sdk removeObserver:self.fileAddedObserver];
        
        if (self.fileAddedObserver.listener) {
            delete self.fileAddedObserver.listener;
            self.fileAddedObserver.listener = NULL;
        }
        
        self.fileAddedObserver = nil;
    }
    
    if (self.disconnectObserver) {
        [self.sdk removeObserver:self.disconnectObserver];
        
        if (self.disconnectObserver.listener) {
            delete self.disconnectObserver.listener;
            self.disconnectObserver.listener = NULL;
        }
        
        self.disconnectObserver = nil;
    }
    
    if (self.powerOffObserver) {
        [self.sdk removeObserver:self.powerOffObserver];
        
        if (self.powerOffObserver.listener) {
            delete self.powerOffObserver.listener;
            self.powerOffObserver.listener = NULL;
        }
        
        self.powerOffObserver = nil;
    }
    
    if (self.chargeStatusObserver) {
        [self.sdk removeObserver:self.chargeStatusObserver];
        
        if (self.chargeStatusObserver.listener) {
            delete self.chargeStatusObserver.listener;
            self.chargeStatusObserver.listener = nullptr;
        }
        
        self.chargeStatusObserver = nil;
    }
    
    if (self.packageDownloadSizeObserver != nil) {
        [self.sdk removeObserver:self.packageDownloadSizeObserver];
        
        if (self.packageDownloadSizeObserver.listener) {
            delete self.packageDownloadSizeObserver.listener;
            self.packageDownloadSizeObserver.listener = nullptr;
        }
        
        self.packageDownloadSizeObserver = nil;
    }
    
    if (self.clientCountObserver != nil) {
        [self.sdk removeObserver:self.clientCountObserver];
        
        if (self.clientCountObserver.listener != nullptr) {
            delete self.clientCountObserver.listener;
            self.clientCountObserver.listener = nullptr;
        }
        
        self.clientCountObserver = nil;
    }
    
    if (self.noTalkingObserver != nil) {
        [self.sdk removeObserver:self.noTalkingObserver];
        
        if (self.noTalkingObserver.listener != nullptr) {
            delete self.noTalkingObserver.listener;
            self.noTalkingObserver.listener = nullptr;
        }
        
        self.noTalkingObserver = nil;
    }
    
    if (self.recvVideoTimeoutObserver != nil) {
        [self.sdk removeObserver:self.recvVideoTimeoutObserver];
        
        if (self.recvVideoTimeoutObserver.listener != nullptr) {
            delete self.recvVideoTimeoutObserver.listener;
            self.recvVideoTimeoutObserver.listener = nullptr;
        }
        
        self.recvVideoTimeoutObserver = nil;
    }
    
    [self removeVideoBitRateObserver];
    self.cameraPropertyValueChangeBlock = nil;
}

- (void)addVideoBitRateObserver {
    SHSDKEventListener *bitRateListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
    self.bitRateObserver = [SHObserver cameraObserverWithListener:bitRateListener eventType:ICATCH_EVENT_VIDEO_BITRATE isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.bitRateObserver];
}

- (void)removeVideoBitRateObserver {
    if (self.bitRateObserver) {
        [self.sdk removeObserver:self.bitRateObserver];
        
        if (self.bitRateObserver.listener) {
            delete self.bitRateObserver.listener;
            self.bitRateObserver.listener = nullptr;
        }
        
        self.bitRateObserver = nil;
    }
}

#pragma mark - NewMessageCount Ops
- (void)incrementNewMessageCount {
    [self incrementNewMessageCountBy:1];
}

- (void)incrementNewMessageCountBy:(NSUInteger)amount {
    self.newMessageCount += amount;
    
    [SHMessageCountManager updateMessageCountCacheWithCameraObj:self];
    if (self.updateNewMessageCount) {
        self.updateNewMessageCount();
    }
}

- (void)resetNewMessageCount {
    self.newMessageCount = 0;
    
    [SHMessageCountManager updateMessageCountCacheWithCameraObj:self];
    if (self.updateNewMessageCount) {
        self.updateNewMessageCount();
    }
}

@end
