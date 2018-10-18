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

#define kChannelsPerFrame   1
#define kBitsPerChannel     16

@interface SHCameraObject ()

@property (nonatomic) SHObserver *batteryLevelObserver;
@property (nonatomic) SHObserver *pirDetectionObserver;
@property (nonatomic) SHObserver *sdCardObserver;
@property (nonatomic) SHObserver *wifiStatusObserver;
@property (nonatomic) SHObserver *fileAddedObserver;
@property (nonatomic) SHObserver *pvThumbnailChangedObserver;
@property (nonatomic) SHObserver *disconnectObserver;
@property (nonatomic) SHObserver *powerOffObserver;

@end

@implementation SHCameraObject

+ (instancetype)cameraObjectWithCamera:(SHCamera *)camera {
	SHCameraObject *obj = [[self alloc] init];
	
	obj.controler = [self createControlCenter];
	obj.gallery = [[SHPhotoGallery alloc] init];
	obj.cameraProperty = [[SHCameraProperty alloc] init];
	obj.camera = camera;
	
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
	NSLog(@"tempPVTime is : %@",tempPVTime);

	if (![tempPVTime isEqualToString:_camera.pvTime] || _camera.pvTime == nil) {
		self.camera.pvTime = tempPVTime;
		
		UIImage *thumbnail = [self.controler.propCtrl retrievePreviewThumbanilWithCamera:self curResult:self.curResult];
		if (thumbnail) {
			self.camera.thumbnail = thumbnail;
            NSData *imgData = UIImageJPEGRepresentation(thumbnail, 0.5);
            //上传到服务器 add by j.chen
            [[SHNetworkManager sharedNetworkManager] updateCameraCoverByCameraID:self.camera.id andCoverData:imgData completion:^(BOOL isSuccess, id  _Nonnull result) {
                if(isSuccess) {
                    NSLog(@"update thumnail success");
                } else {
                    NSLog(@"update thumnail fail");
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
                        NSLog(@"update device cover success");
                    } else {
                        NSLog(@"update device cover failure");
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
			NSLog(@" to connect camera,camera name is : %@",self.camera.cameraName);
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
	SHSDK *sdk = [[SHSDK alloc] init];
	int retValue = ICH_SUCCEED;
	//dispatch_async([sdk sdkQueue], ^{
		NSLog(@" to connect camera,camera name is : %@",self.camera.cameraName);
    if (self.camera == nil || self.camera.cameraUid == nil) {
        SHLogError(SHLogTagAPP, @"camera or camera uid is nil.");

        return ICH_TUTK_IOTC_CONNECTION_UNKNOWN_ER;
    }
        if ((retValue = [sdk initializeSHSDK:self.camera.cameraUid devicePassword:self.camera.devicePassword]) == ICH_SUCCEED) {
            
            self.streamOper = [[SHStreamOperate alloc] initWithCameraObject:self];
            self.controler.actCtrl.shCamObj = self;
            self.controler.fileCtrl.shCamObj = self;
            self.gallery.shCamObj = self;
            self.sdk = sdk;
            self.cameraProperty.previewMode = 0;
            
            if ([sdk isSHSDKInitialized]) {
                self.isConnect = YES;
                [self addCameraPropertyObserver];
            } else {
                
            }
        } else {
            self.startPV = NO;
        }
    
	return retValue;
		//
//		SHLogInfo(SHLogTagAPP, @"NotReachable -- Sleep 500ms");
//		[NSThread sleepForTimeInterval:0.5];
	//});
}

- (void)initCamera {
//    [self addCameraPropertyObserver];
//    [self updatePreviewThumbnail];
    
//    [self openAudioServer];
    
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
    _sdk = nil;
    _streamOper = nil;
}

- (void)openAudioServer {
    if (self.cameraProperty.serverOpened) {
        SHLogInfo(SHLogTagAPP, @"Audio server already opened.");
        return;
    }
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
//    });
}

- (void)disConnectWithSuccessBlock:(void(^)())successBlock failedBlock:(void(^)())failedBlock {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		
		dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
		if ((dispatch_semaphore_wait(self.semaphore, time) != 0)) {
			if (failedBlock) {
				failedBlock();
			}
		} else {
            dispatch_semaphore_signal(self.semaphore);
        
            [self removeCameraPropertyObserver];
            //delete download list before disconnect
            [[SHDownloadManager shareDownloadManger] clearDownloadingByUid:self.camera.cameraUid];
            [self.sdk destroySHSDK];
            [self.streamOper uploadPreviewThumbnailToServer];
            [self cleanCamera];

            if (successBlock) {
                successBlock();
            }
		}
	});
}


#pragma mark - Observer
- (void)addCameraPropertyObserver {
	SHSDKEventListener *batteryLevelListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.batteryLevelObserver = [SHObserver cameraObserverWithListener:batteryLevelListener eventType:ICATCH_EVENT_BATTERY_LEVEL_CHANGED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.batteryLevelObserver];
	/*
	SHSDKEventListener *pirListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.pirDetectionObserver = [SHObserver cameraObserverWithListener:pirListener eventType:ICATCH_EVENT_PIR_DETECTION_CHANGED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.pirDetectionObserver];
	*/
	SHSDKEventListener *sdCardListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.sdCardObserver = [SHObserver cameraObserverWithListener:sdCardListener eventType:ICATCH_EVENT_SDCARD_INFO_CHANGED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.sdCardObserver];
	/*
	SHSDKEventListener *wifiStatusListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.wifiStatusObserver = [SHObserver cameraObserverWithListener:wifiStatusListener eventType:ICATCH_EVENT_WIFI_SIGNAL_LEVEL_CHANGED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.wifiStatusObserver];
	*/
	SHSDKEventListener *fileAddedListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.fileAddedObserver = [SHObserver cameraObserverWithListener:fileAddedListener eventType:ICATCH_EVENT_FILE_ADDED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.fileAddedObserver];
	/*
	SHSDKEventListener *pvThumbnailChangedListener = new SHSDKEventListener(self, @selector(cameraPropertyValueChangeCallback:));
	self.pvThumbnailChangedObserver = [SHObserver cameraObserverWithListener:pvThumbnailChangedListener eventType:ICATCH_EVENT_PV_THUMBNAIL_CHANGED isCustomized:NO isGlobal:NO];
	[self.sdk addObserver:self.pvThumbnailChangedObserver];
    */
    SHSDKEventListener *disconnectListener = new SHSDKEventListener(self, @selector(notifyDisconnectionEvent));
    self.disconnectObserver = [SHObserver cameraObserverWithListener:disconnectListener eventType:ICATCH_EVENT_CONNECTION_DISCONNECTED isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.disconnectObserver];
    
    SHSDKEventListener *powerOffListener = new SHSDKEventListener(self, @selector(notifyCameraPowerOffEvent:));
    self.powerOffObserver = [SHObserver cameraObserverWithListener:powerOffListener eventType:ICATCH_EVENT_CAMERA_POWER_OFF isCustomized:NO isGlobal:NO];
    [self.sdk addObserver:self.powerOffObserver];
}

- (void)cameraPropertyValueChangeCallback:(SHICatchEvent *)evt {
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

- (void)removeCameraPropertyObserver {
	if (self.batteryLevelObserver) {
		[self.sdk removeObserver:self.batteryLevelObserver];
		
		if (self.batteryLevelObserver.listener) {
			delete self.batteryLevelObserver.listener;
			self.batteryLevelObserver.listener = NULL;
		}
		
		self.batteryLevelObserver = nil;
	}
	
	if (self.pirDetectionObserver) {
		[self.sdk removeObserver:self.pirDetectionObserver];
		
		if (self.pirDetectionObserver.listener) {
			delete self.pirDetectionObserver.listener;
			self.pirDetectionObserver.listener = NULL;
		}
		
		self.pirDetectionObserver = nil;
	}
	
	if (self.sdCardObserver) {
		[self.sdk removeObserver:self.sdCardObserver];
		
		if (self.sdCardObserver.listener) {
			delete self.sdCardObserver.listener;
			self.sdCardObserver.listener = NULL;
		}
		
		self.sdCardObserver = nil;
	}
	
	if (self.wifiStatusObserver) {
		[self.sdk removeObserver:self.wifiStatusObserver];
		
		if (self.wifiStatusObserver.listener) {
			delete self.wifiStatusObserver.listener;
			self.wifiStatusObserver.listener = NULL;
		}
		
		self.wifiStatusObserver = nil;
	}
    
    if (self.fileAddedObserver) {
        [self.sdk removeObserver:self.fileAddedObserver];
        
        if (self.fileAddedObserver.listener) {
            delete self.fileAddedObserver.listener;
            self.fileAddedObserver.listener = NULL;
        }
        
        self.fileAddedObserver = nil;
    }
    
    if (self.pvThumbnailChangedObserver) {
        [self.sdk removeObserver:self.pvThumbnailChangedObserver];
        
        if (self.pvThumbnailChangedObserver.listener) {
            delete self.pvThumbnailChangedObserver.listener;
            self.pvThumbnailChangedObserver.listener = NULL;
        }
        
        self.pvThumbnailChangedObserver = nil;
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
}

@end
