// SHNetworkManager+SHFaceHandle.m

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
 
 // Created by zj on 2019/1/7 1:53 PM.
    

#import "SHNetworkManager+SHFaceHandle.h"
#import "SHUserAccount.h"
#import <AFNetworking/AFNetworking.h>

@implementation SHNetworkManager (SHFaceHandle)

- (void)faceRecognitionWithPicture:(NSData *)data deviceID:(NSString *)deviceID finished:(_Nullable ZJRequestCallBack)finished {
    if (data == nil || data.length == 0 || deviceID == nil) {
        if (finished) {
            NSDictionary *dict = @{
                                   NSLocalizedDescriptionKey: @"invalid parameter.",
                                   };
            finished(nil, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
        }
        
        return;
    }
    
    NSString *dataString = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    
    NSString *dateString = [formatter stringFromDate:date];
    
    NSDictionary *parameters = @{
                                 @"id": deviceID,
                                 @"image": dataString,
                                 @"time": dateString,
                                 @"customerid": kServerCustomerid,
                                 };
    
    [self requestWithMethod:ZJRequestMethodPOST opertionType:ZJOperationTypeDevice urlString:FACE_RECOGNITION_PATH parametes:parameters finished:finished];
}

- (ZJRequestError *)createErrorWithCode:(NSInteger)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict {
    //    return [[NSError alloc] initWithDomain:NSItemProviderErrorDomain code:code userInfo:dict];
    return [ZJRequestError requestErrorWithDict:dict];
}

- (void)uploadFacePicture:(NSData *)data name:(NSString *)name finished:(_Nullable ZJRequestCallBack)finished {
    if (data == nil || data.length == 0 || name == nil) {
        if (finished) {
            NSDictionary *dict = @{
                                   NSLocalizedDescriptionKey: @"invalid parameter.",
                                   };
            finished(nil, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
        }
        
        return;
    }
    
    NSString *dataString = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    SHLogInfo(SHLogTagAPP, @"data size: %f k", (double)dataString.length / 1024);
    
    NSDictionary *parameters = @{
                                 @"name": name,
                                 @"image": dataString,
                                 };
    
    //    [self uploadDataWithURLString:FACES_MANAGE_PATH parameters:parameters finished:finished];
    [self tokenRequestWithMethod:ZJRequestMethodPOST opertionType:ZJOperationTypeFaces urlString:FACES_MANAGE_PATH parametes:parameters finished:finished];
}

- (void)deleteFacePictureWithName:(NSString *)name finished:(ZJRequestCallBack)finished {
    if (name == nil) {
        if (finished) {
            NSDictionary *dict = @{
                                   NSLocalizedDescriptionKey: @"invalid parameter.",
                                   };
            finished(nil, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
            
            return;
        }
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@?name=%@", FACES_MANAGE_PATH, name];
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    //    [self facesRequestWithMethod:ZJRequestMethodDELETE urlString:urlString parametes:nil finished:finished];
    [self tokenRequestWithMethod:ZJRequestMethodDELETE opertionType:ZJOperationTypeFaces urlString:urlString parametes:nil finished:finished];
}

- (void)getFacesInfoWithName:(NSString * _Nullable)name finished:(ZJRequestCallBack)finished {
    NSDictionary *parametes = nil;
    
    if (name != nil && name.length > 0) {
        parametes = @{
                      @"name": name,
                      };
    }
    
    [self tokenRequestWithMethod:ZJRequestMethodGET opertionType:ZJOperationTypeFaces urlString:FACES_MANAGE_PATH parametes:parametes finished:finished];
}

- (void)replaceFacePicture:(NSData *)data name:(NSString *)name finished:(ZJRequestCallBack)finished {
    if (data == nil || data.length == 0 || name == nil) {
        if (finished) {
            NSDictionary *dict = @{
                                   NSLocalizedDescriptionKey: @"invalid parameter.",
                                   };
            finished(nil, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
        }
        
        return;
    }
    
    NSString *dataString = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    SHLogInfo(SHLogTagAPP, @"data size: %f k", (double)dataString.length / 1024);

    NSDictionary *parameters = @{
                                 @"name": name,
                                 @"image": dataString,
                                 };
    
    [self tokenRequestWithMethod:ZJRequestMethodPUT opertionType:ZJOperationTypeFaces urlString:FACES_MANAGE_PATH parametes:parameters finished:finished];
}

- (NSString *)requestURLString:(NSString *)urlString {
    return [ServerBaseUrl stringByAppendingString:urlString];
}

- (void)uploadDataWithURLString:(NSString *)urlString parameters:(id)parameters finished:(ZJRequestCallBack)finished {
    if (self.userAccount.access_token == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
    }
    
    NSString *token = [@"Bearer " stringByAppendingString:self.userAccount.access_token ? self.userAccount.access_token : @""];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    
    [manager POST:[self requestURLString:urlString] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (finished) {
            finished(responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithNSError:error]);
        }
    }];
}

- (AFHTTPSessionManager *)facesRequestSessionManager {
    if (self.userAccount.access_token == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
    }
    
    NSString *token = [@"Bearer " stringByAppendingString:self.userAccount.access_token ? self.userAccount.access_token : @""];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    
    return manager;
}

- (void)tokenRequestWithMethod:(ZJRequestMethod)method opertionType:(ZJOperationType)opertionType urlString:(NSString *)urlString parametes:(id)parametes finished:(_Nullable ZJRequestCallBack)finished {
    
    if ([self.userAccount access_tokenHasEffective]) {
        [self requestWithMethod:method opertionType:opertionType urlString:urlString parametes:parametes finished:finished];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                [self requestWithMethod:method opertionType:opertionType urlString:urlString parametes:parametes finished:finished];
            } else {
                if (finished) {
                    finished(nil, result);
                }
            }
        }];
    }
}

- (void)requestWithMethod:(ZJRequestMethod)method opertionType:(ZJOperationType)operationType urlString:(NSString *)urlString parametes:(id)parametes finished:(_Nullable ZJRequestCallBack)finished {
    switch (operationType) {
        case ZJOperationTypeFaces:
            [self facesRequestWithMethod:method urlString:urlString parametes:parametes finished:finished];
            break;
            
        case ZJOperationTypeOAuth:
            [self requestWithMethod:method urlString:urlString parametes:parametes finished:finished];
            break;
            
        case ZJOperationTypeDevice:
            [self requestWithMethod:method urlString:urlString parametes:parametes finished:finished];
            break;
            
        default:
            break;
    }
}

- (void)facesRequestWithMethod:(ZJRequestMethod)method urlString:(NSString *)urlString parametes:(id)parametes finished:(_Nullable ZJRequestCallBack)finished {
    id success = ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (finished) {
            finished(responseObject, nil);
        }
    };
    
    id faiure = ^(NSURLSessionDataTask *_Nonnull task, NSError * _Nonnull error) {
        
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 403) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:error];
        }
        
        SHLogError(SHLogTagAPP, @"网络请求错误： %@", error);
        
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithNSError:error]);
        }
    };
    
    urlString = [self requestURLString:urlString];
    AFHTTPSessionManager *manager = [self facesRequestSessionManager];
    
    switch (method) {
        case ZJRequestMethodGET:
            [manager GET:urlString parameters:parametes progress:nil success:success failure:faiure];
            break;
            
        case ZJRequestMethodPOST:
            [manager POST:urlString parameters:parametes progress:nil success:success failure:faiure];
            break;
            
        case ZJRequestMethodPUT:
            [manager PUT:urlString parameters:parametes success:success failure:faiure];
            break;
            
        case ZJRequestMethodDELETE:
            [manager DELETE:urlString parameters:parametes success:success failure:faiure];
            break;
            
        default:
            break;
    }
}

- (void)requestWithMethod:(ZJRequestMethod)method urlString:(NSString *)urlString parametes:(id)parametes finished:(ZJRequestCallBack)finished {
    
    id success = ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (finished) {
            finished(responseObject, nil);
        }
    };
    
    id failure = ^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 403) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:error];
        }
        
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithNSError:error]);
        }
    };
    
    urlString = [self requestURLString:urlString];
    
    switch (method) {
        case ZJRequestMethodGET:
            [[AFHTTPSessionManager manager] GET:urlString parameters:parametes progress:nil success:success failure:failure];
            break;
            
        case ZJRequestMethodPOST:
            [[AFHTTPSessionManager manager] POST:urlString parameters:parametes progress:nil success:success failure:failure];
            break;
            
        case ZJRequestMethodDELETE:
            [[AFHTTPSessionManager manager] DELETE:urlString parameters:parametes success:success failure:failure];
            break;
            
        default:
            break;
    }
}

@end
