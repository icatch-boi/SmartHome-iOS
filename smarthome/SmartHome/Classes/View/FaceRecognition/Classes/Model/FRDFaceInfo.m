//
//  FRDFaceInfo.m
//  FaceRecognition
//
//  Created by ZJ on 2018/9/13.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "FRDFaceInfo.h"
#import "FaceCollectCommon.h"
#import "SHNetworkManager+SHFaceHandle.h"

@interface FRDFaceInfo ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *faceid;
@property (nonatomic, copy) NSNumber *expires;
@property (nonatomic, copy) NSNumber *facesnum;
@property (nonatomic, strong) UIImage *faceImage;

@end

@implementation FRDFaceInfo

+ (instancetype)faceInfoWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"faceid"]) {
        self.faceid = [value stringValue];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (void)getFaceImageWithCompletion:(FaceInfoGetFaceImageCompletionBlock)completion {
    if (_faceImage) {
        if (completion) {
            completion(_faceImage);
        }
    } else {
        if (_faceid != nil) {
            UIImage *image = [[ZJImageCache sharedImageCache] imageFromCacheForKey:FaceCollectImageKey([SHNetworkManager sharedNetworkManager].userAccount.id, _faceid)];
            if (image != nil) {
                _faceImage = image;
                if (completion) {
                    completion(image);
                }
                
                return;
            }
        }
        
#ifndef KUSE_S3_SERVICE
        [[SHNetworkManager sharedNetworkManager] downloadWithURLString:_url finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
            if (error != nil) {
                SHLogError(SHLogTagAPP, @"Get face image failed, error: %@", error.error_description);
                if (completion) {
                    completion(nil);
                }
            } else {
                if (result != nil && [result isKindOfClass:[NSData class]]) {
                    UIImage *image = [[UIImage alloc] initWithData:result];
                    
                    _faceid ? [[ZJImageCache sharedImageCache] storeImage:image forKey:FaceCollectImageKey([SHNetworkManager sharedNetworkManager].userAccount.id, _faceid) completion:nil] : void();
                    
                    _faceImage = image;
                    
                    if (completion) {
                        completion(image);
                    }
                } else {
                    if (completion) {
                        completion(nil);
                    }
                }
            }
        }];
#else
        [[SHENetworkManager sharedManager] getFaceImageWithFaceid:_faceid completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                UIImage *image = result;
                
                _faceid ? [[ZJImageCache sharedImageCache] storeImage:image forKey:FaceCollectImageKey([SHNetworkManager sharedNetworkManager].userAccount.id, _faceid) completion:nil] : void();

                _faceImage = image;
                
                if (completion) {
                    completion(image);
                }
            } else {
                SHLogError(SHLogTagAPP, @"Get face image failed, error: %@", result);
                if (completion) {
                    completion(nil);
                }
            }
        }];
#endif
    }
}

@end
