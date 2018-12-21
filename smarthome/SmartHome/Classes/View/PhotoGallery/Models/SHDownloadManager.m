//
//  SHDownloadManager.m
//  SmartHome
//
//  Created by ZJ on 2017/6/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHDownloadManager.h"
#import "SHDownloader.h"

@interface SHDownloadManager () <SHDownloadInfoDelegate>
@property (nonatomic, readwrite) NSMutableArray *downloadArray;
@property (nonatomic, strong) NSMutableDictionary *downLoaderCache;
@property (nonatomic, readwrite) int downloadSuccessedNum;
@property (nonatomic, readwrite) int downloadFailedNum;
@property (nonatomic, readwrite) int cancelDownloadNum;
@property (nonatomic, assign) BOOL cleanDownload;

@end

@implementation SHDownloadManager

- (NSMutableArray *)downloadArray {
	if (!_downloadArray) {
		_downloadArray = [NSMutableArray array];
	}
	
	return _downloadArray;
}

- (NSMutableDictionary *)downLoaderCache {
	if (!_downLoaderCache) {
		_downLoaderCache = [NSMutableDictionary dictionaryWithCapacity:kMaxDownloadNum];
	}
	
	return _downLoaderCache;
}


+ (instancetype)shareDownloadManger {
	static id instance = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [self new];
	});
	
	return instance;
}

//- (void)cancelDownloadFile:(SHFile *)file successBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock {
//	id key = [NSString stringWithFormat:@"%@_%@",file.uid,[NSString stringWithFormat:@"%d",file.f.getFileHandle()]];
//
//	SHDownloader *downloader = [self.downLoaderCache objectForKey:key];
//	if(downloader == nil){//current file is not downloading
//		successBlock();//return success
//	}else{//is downloading
//		[downloader cancelDownloadFile:file successBlock:successBlock failedBlock:failedBlock];
//	}
//}


- (Boolean)cancelDownloadFile:(SHFile *)file {
	SHLogInfo(SHLogTagAPP, @"cancelDownloadFile filename is %s", file.f.getFileName().c_str());
	id key = [NSString stringWithFormat:@"%@_%@",file.uid,[NSString stringWithFormat:@"%d",file.f.getFileHandle()]];
	SHDownloader *downloader = [self.downLoaderCache objectForKey:key];
    SHLogInfo(SHLogTagAPP, @"downloader is: %@", downloader);
	if(downloader == nil){//current file is not downloading
		self.downloadFailedNum++;
		int position = [self findPositionByFile:file];
        if (self.cleanDownload == NO) {
            [self.downloadArray removeObject:file];
        }
		id key = [NSString stringWithFormat:@"%@_%@",file.uid,[NSString stringWithFormat:@"%d",file.f.getFileHandle()]];
		[self.downLoaderCache removeObjectForKey:key];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.downloadInfoDelegate onCancelDownloadComplete:position retValue:YES];
			[self startDownloadFile];
		});
		return YES;
	}else{//is downloading
		return [downloader cancelDownloadFile:file];
	}
}

- (void)downloadWithfile:(SHFile *)file {
	//key = uid_filehandle
	if(self.downLoaderCache.count == kMaxDownloadNum){
		return;
	}
	
	SHCameraObject *camObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:file.uid];
	SHDownloader *downloader = [[SHDownloader alloc] initWithCameraObject:camObj];
	downloader.delegate = self;
	id key = [NSString stringWithFormat:@"%@_%@",file.uid,[NSString stringWithFormat:@"%d",file.f.getFileHandle()]];
	[self.downLoaderCache setObject:downloader forKey:key];
	[downloader downloadFile:file];
}


-(void)clearDownloadingByUid:(NSString*) uid{
    self.cleanDownload = YES;
	//delete download list while disconnect
	NSMutableArray *downloadList = [SHDownloadManager shareDownloadManger].downloadArray;
    SHLogInfo(SHLogTagAPP, @"download list num: %lu", (unsigned long)downloadList.count);
    if(downloadList != nil && downloadList.count > 0){
		for(int ii = 0; ii < downloadList.count;){
			SHFile *file = [downloadList objectAtIndex:ii];
			if([file.uid isEqualToString:uid]){
				[self cancelDownloadFile:file];
                if (ii < downloadList.count) {
                    [downloadList removeObjectAtIndex:ii];
                }
			}else{
				ii++;
			}
		}
	}
    self.cleanDownload = NO;
}

- (void)addDownloadFile:(SHFile *)file{
	if([self isExistInDownloadListByFile:file] == YES){
		return;
	}
#if 0
	//reset the stastics when starting new download
	if(self.downloadArray.count == 0){
		self.downloadFailedNum = 0;
		self.downloadSuccessedNum = 0;
		self.cancelDownloadNum = 0;
	}
#endif
	[self.downloadArray insertObject:file atIndex:(self.downloadArray.count)];
    SHLogInfo(SHLogTagAPP, "addDownloadFile cout is : %lu", (unsigned long)self.downloadArray.count);
}

- (void)startDownloadFile{
	if(self.downloadArray.count == 0){
		return;
	}
	[self downloadWithfile:[self.downloadArray objectAtIndex:0]];
}

- (void)onDownloadComplete:(SHFile*)file retvalue:(Boolean)ret{
	SHLogInfo(SHLogTagAPP, @"onDownloadComplete filename is %s", file.f.getFileName().c_str());
	if(ret == YES){
		self.downloadSuccessedNum++;
	}else{
		self.downloadFailedNum++;
	}
	int position = [self findPositionByFile:file];
	[self.downloadArray removeObject:file];
	id key = [NSString stringWithFormat:@"%@_%@",file.uid,[NSString stringWithFormat:@"%d",file.f.getFileHandle()]];
	[self.downLoaderCache removeObjectForKey:key];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.downloadInfoDelegate onDownloadComplete:position retValue:ret];
		[self startDownloadFile];
		if(self.downloadArray.count == 0){
			[self.allDownloadCompletedelegate onAllDownloadComplete];
		}
	});
}

- (void)onCancelDownloadComplete:(SHFile*)file retvalue:(Boolean)ret{
	SHLogInfo(SHLogTagAPP, @"onCancelDownloadComplete filename is %s", file.f.getFileName().c_str());
	if(ret == YES){
		self.cancelDownloadNum++;
		int position = [self findPositionByFile:file];
		[self.downloadArray removeObject:file];
		id key = [NSString stringWithFormat:@"%@_%@",file.uid,[NSString stringWithFormat:@"%d",file.f.getFileHandle()]];
		[self.downLoaderCache removeObjectForKey:key];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.downloadInfoDelegate onCancelDownloadComplete:position retValue:ret];
			[self startDownloadFile];
			if(self.downloadArray.count == 0){
				[self.allDownloadCompletedelegate onAllDownloadComplete];
			}
		});
	}
}

- (void)onProgressUpdate:(SHFile*)file progress:(int)progress{
//	SHLogInfo(SHLogTagAPP, @"onProgressUpdate filename is %@, progress is %d",[NSString stringWithCString:file.f.getFileName().c_str()],progress);
	int position = [self findPositionByFile:file];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.downloadInfoDelegate onProgressUpdate:position progress:progress];
	});
}

- (int)findPositionByFile:(SHFile*)file{
	if(self.downloadArray.count == 0){
		return -1;
	}
	for(int ii = 0; ii < self.downloadArray.count;ii++){
		SHFile *tempFile = [self.downloadArray objectAtIndex:ii];
		if([file.uid isEqualToString:tempFile.uid]
		   && file.f.getFileHandle() == tempFile.f.getFileHandle()){
			return ii;
		}
	}
	return -1;
}

- (Boolean)isExistInDownloadListByFile:(SHFile*)file{
	if(self.downloadArray.count == 0){
		return NO;
	}
	for(int ii = 0; ii < self.downloadArray.count;ii++){
		SHFile *tempFile = [self.downloadArray objectAtIndex:ii];
		if([file.uid isEqualToString:tempFile.uid]
		   && file.f.getFileHandle() == tempFile.f.getFileHandle()){
			return YES;
		}
	}
	return NO;
}

- (Boolean)isAllDownloadComplete{
	if(self.downloadArray.count == 0){
		return YES;
	}
	return NO;
}

- (Boolean)isExistInDownloadListByCamera:(SHCameraObject*)camera{
	if(self.downloadArray.count == 0){
		return NO;
	}
	for(int ii = 0; ii < self.downloadArray.count;ii++){
		SHFile *tempFile = [self.downloadArray objectAtIndex:ii];
		if([camera.camera.cameraUid isEqualToString:tempFile.uid]){
			return YES;
		}
	}
	return NO;
}
#pragma -mark test
@end
