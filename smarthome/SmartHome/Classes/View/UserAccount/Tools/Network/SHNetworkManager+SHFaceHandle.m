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
#import "FaceCollectCommon.h"

#define kBOUNDARY @"abc123"

@implementation SHNetworkManager (SHFaceHandle)

- (void)faceRecognitionWithPicture:(NSData *)data deviceID:(NSString *)deviceID finished:(_Nullable ZJRequestCallBack)finished {
    if (data == nil || data.length == 0 || deviceID == nil) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
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
                                 @"customerid": kServerCustomerID,
                                 };
    
    [self requestWithMethod:ZJRequestMethodPOST opertionType:ZJOperationTypeDevice urlString:FACE_RECOGNITION_PATH parametes:parameters finished:finished];
}

- (void)uploadFacePicture:(NSData *)data name:(NSString *)name finished:(_Nullable ZJRequestCallBack)finished {
    if (data == nil || data.length == 0 || name == nil) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
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
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
            
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
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
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
    return [kServerBaseURL stringByAppendingString:urlString];
}

- (void)uploadDataWithURLString:(NSString *)urlString parameters:(id)parameters finished:(ZJRequestCallBack)finished {
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
        
        if (respose.statusCode == 401) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        }
        
        SHLogError(SHLogTagAPP, @"网络请求错误： %@", error);
        
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithNSError:error]);
        }
    };
    
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        urlString = [self requestURLString:urlString];
    }
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
        
        if (respose.statusCode == 401) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        }
        
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithNSError:error]);
        }
    };
    
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        urlString = [self requestURLString:urlString];
    }
    
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

// new api
- (void)getAvailableFaceid:(ZJRequestCallBack)finished {
    [self tokenRequestWithMethod:ZJRequestMethodGET opertionType:ZJOperationTypeFaces urlString:kGetFaceID parametes:nil finished:finished];
}

- (void)uploadFaceData:(NSData *)faceData faceid:(NSString *)faceid name:(NSString *)name finished:(_Nullable ZJRequestCallBack)finished {
    if (faceData == nil || faceData.length == 0 || faceid == nil || [faceid isEqualToString:@""] || name == nil) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSDictionary *parameters = @{
                                 @"name": name,
                                 @"faceid": faceid,
                                 };
    
    NSString *urlString = [self requestURLString:kFaceInfo];
    [[self facesRequestSessionManager] POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:faceData name:@"image" fileName:[@"FaceInfo-" stringByAppendingString:faceid] mimeType:@"multipart/form-data"];
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (finished) {
            finished(responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 401) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        }
        
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithNSError:error]);
        }
    }];
}

- (void)updateFaceData:(NSData *)faceData faceid:(NSString *)faceid name:(NSString *)name finished:(_Nullable ZJRequestCallBack)finished {
    if (faceData == nil || faceData.length == 0 || faceid == nil || [faceid isEqualToString:@""] || name == nil) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSDictionary *parameters = @{
                                 @"name": name,
                                 @"faceid": faceid,
                                 };
    
    NSString *urlString = [self requestURLString:kFaceInfo];
    
    [self putRequest:urlString filedName:@"image" fileName:[@"FaceInfo-" stringByAppendingString:faceid] formData:faceData parameters:parameters finished:finished];
}

- (void)putRequest:(NSString *)urlString filedName:(NSString *)filedName fileName:(NSString *)fileName formData:(NSData *)formData parameters:(id)parameters finished:(_Nullable ZJRequestCallBack)finished {
    NSURL *url = [NSURL URLWithString:urlString];
    if (urlString == nil || url == nil) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = @"PUT";
    
    //    request.allHTTPHeaderFields = @{@"":@""}//此处为请求头，类型为字典
    NSString *token = [@"Bearer " stringByAppendingString:self.userAccount.access_token ? self.userAccount.access_token : @""];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kBOUNDARY] forHTTPHeaderField:@"Content-Type"];
    
    request.HTTPBody = [self makeBodyWithFiledName:filedName fileName:fileName datas:@[formData] params:parameters];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            SHLogError(SHLogTagAPP, @"连接错误: %@", error);
            if (finished) {
                finished(nil, [ZJRequestError requestErrorWithNSError:error]);
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 304 || httpResponse.statusCode == 204) {
            // 解析数据
//            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
//
//            SHLogInfo(SHLogTagAPP, @"json: %@", json);
            if (finished) {
                finished(data, nil);
            }
        } else {
            if (httpResponse.statusCode == 401) {
                SHLogError(SHLogTagAPP, @"Token invalid.");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
            }
            
            SHLogError(SHLogTagAPP, @"服务器内部错误");
            NSDictionary *dict = @{
                                   @"error_description": @"Unknown Error",
                                   };
            if (finished) {
                finished(nil, [ZJRequestError requestErrorWithDict:dict]);
            }
        }
    }] resume];
}

- (NSData *)makeBodyWithFiledName:(NSString *)filedName fileName:(NSString *)fileName datas:(NSArray *)datas params:(NSDictionary *)params {
    NSMutableData *mData = [NSMutableData data];
    // 拼文件
    [datas enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableString *mString = [NSMutableString string];
        if (idx == 0) {
            [mString appendFormat:@"--%@\r\n", kBOUNDARY];
        } else {
            [mString appendFormat:@"\r\n--%@\r\n", kBOUNDARY];
        }
        
        NSString *name = (idx > 0) ? [NSString stringWithFormat:@"%@-%d", fileName, idx] : fileName;
        [mString appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", filedName, name];
        [mString appendString:@"Content-Type: application/octet-stream\r\n"];

        [mString appendString:@"\r\n"];
        
        // 把字符串转换成data
        [mData appendData:[mString dataUsingEncoding:NSUTF8StringEncoding]];
        
        // 加载文件
        NSData *data = obj; //[NSData dataWithContentsOfFile:obj];
        
        [mData appendData:data];
    }];
    
    // 拼字符串
    [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableString *mString = [NSMutableString string];
        
        [mString appendFormat:@"\r\n--%@\r\n", kBOUNDARY];
        [mString appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", key];
        [mString appendString:@"\r\n"];
        
        [mString appendFormat:@"%@", obj];
        
        [mData appendData:[mString dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // 结束
    NSString *end = [NSString stringWithFormat:@"\r\n--%@--", kBOUNDARY];
    [mData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    return mData.copy;
}

- (void)getFaceInfoWithFaceid:(NSString *)faceid finished:(_Nullable ZJRequestCallBack)finished {
    if (faceid == nil || [faceid isEqualToString:@""]) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSDictionary *parameters = @{
                                 @"faceid": faceid,
                                 };
    NSString *urlString = [self requestURLString:kFaceInfo];

#if 0
    [self tokenRequestWithMethod:ZJRequestMethodGET opertionType:ZJOperationTypeFaces urlString:urlString parametes:parameters finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        if (error != nil) {
            if (finished) {
                finished(nil, error);
            }
        } else {
            NSString *urlString = result[@"url"];
            if (urlString == nil) {
                if (finished) {
                    NSDictionary *dict = @{
                                           @"error_description": @"The url is nil.",
                                           };
                    if (finished) {
                        finished(nil, [ZJRequestError requestErrorWithDict:dict]);
                    }
                }
            } else {
                [self downloadWithURLString:urlString finished:finished];
            }
        }
    }];
#else
    [self tokenRequestWithMethod:ZJRequestMethodGET opertionType:ZJOperationTypeFaces urlString:urlString parametes:parameters finished:finished];
#endif
}

- (void)getFacesInfoWithFinished:(_Nullable ZJRequestCallBack)finished {
    [self tokenRequestWithMethod:ZJRequestMethodGET opertionType:ZJOperationTypeFaces urlString:kFaceInfo parametes:nil finished:finished];
}

- (void)deleteFaceDataWithFaceid:(NSString *)faceid finished:(_Nullable ZJRequestCallBack)finished {
    if (faceid == nil || [faceid isEqualToString:@""]) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSDictionary *parameters = @{
                                 @"faceid": faceid,
                                 };
    NSString *urlString = [self requestURLString:kFaceInfo];
    
    [self tokenRequestWithMethod:ZJRequestMethodDELETE opertionType:ZJOperationTypeFaces urlString:urlString parametes:parameters finished:finished];
    [[ZJImageCache sharedImageCache] removeImageForKey:FaceCollectImageKey(self.userAccount.id, faceid) completion:nil];
}

- (void)uploadFaceDataSet:(NSData *)faceDataSet faceid:(NSString *)faceid finished:(_Nullable ZJRequestCallBack)finished {
    if (faceDataSet == nil || faceDataSet.length == 0 || faceid == nil || [faceid isEqualToString:@""]) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSDictionary *parameters = @{
                                 @"faceid": @([faceid integerValue]),
                                 @"facesnum": @(5),
                                 };
    
    NSString *urlString = [self requestURLString:kFaceDataSet];
    [[self facesRequestSessionManager] POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:faceDataSet name:@"metadata" fileName:[@"FaceDataSet-" stringByAppendingString:faceid] mimeType:@"multipart/form-data"];
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (finished) {
            finished(responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 401) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        }
        
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithNSError:error]);
        }
    }];
}

- (void)getFaceDataSetWithFaceid:(NSString *)faceid finished:(_Nullable ZJRequestCallBack)finished {
#ifndef KUSE_S3_SERVICE
    
    if (faceid == nil || [faceid isEqualToString:@""]) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSDictionary *parameters = @{
                                 @"faceid": faceid,
                                 };
    NSString *urlString = [self requestURLString:kFaceDataSet];
    
    [self tokenRequestWithMethod:ZJRequestMethodGET opertionType:ZJOperationTypeFaces urlString:urlString parametes:parameters finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        if (error != nil) {
            if (finished) {
                finished(nil, error);
            }
        } else {
            NSString *urlString = result[@"url"];
            if (urlString == nil) {
                if (finished) {
                    NSDictionary *dict = @{
                                           @"error_description": @"The url is nil.",
                                           };
                    if (finished) {
                        finished(nil, [ZJRequestError requestErrorWithDict:dict]);
                    }
                }
            } else {
                [self downloadWithURLString:urlString finished:finished];
            }
        }
    }];
#else
    [[SHENetworkManager sharedManager] getFaceSetDataWithFaceid:faceid completion:^(BOOL isSuccess, id  _Nullable result) {
        
        if (finished) {
            isSuccess ? finished(result, nil) : finished(nil, result);
        }
    }];
#endif
}

- (void)downloadWithURLString:(NSString *)urlString finished:(ZJRequestCallBack)finished {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIME_OUT_INTERVAL];
    
    if (urlString == nil || url == nil || request == nil) {
        SHLogError(SHLogTagAPP, @"Download failed, urlString or url or request is nil.\n\t urlString: %@, url: %@, request: %@.", urlString, url, request);
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            SHLogError(SHLogTagAPP, @"连接错误: %@", error);
            if (finished) {
                finished(nil, [ZJRequestError requestErrorWithNSError:error]);
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 304 || httpResponse.statusCode == 204) {
            // 解析数据
//            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            
//            SHLogInfo(SHLogTagAPP, @"json: %@", json);
            if (finished) {
                finished(data, nil);
            }
        } else {
            if (httpResponse.statusCode == 401) {
                SHLogError(SHLogTagAPP, @"Token invalid.");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
            }
            
            SHLogError(SHLogTagAPP, @"服务器内部错误");
            NSDictionary *dict = @{
                                   @"error_description": @"Unknown Error",
                                   };
            if (finished) {
                finished(nil, [ZJRequestError requestErrorWithDict:dict]);
            }
        }
        
    }] resume];
}

- (void)getStrangerFaceInfoWithDeviceid:(NSString *)deviceid finished:(_Nullable ZJRequestCallBack)finished {
    if (deviceid.length == 0) {
        if (finished) {
            finished(nil, [ZJRequestError requestErrorWithDescription:@"invalid parameter."]);
        }
        
        return;
    }
    
    NSDictionary *parameters = @{
                                 @"id": deviceid,
                                 };
    
    [self tokenRequestWithMethod:ZJRequestMethodGET opertionType:ZJOperationTypeFaces urlString:kFaceimagePath parametes:parameters finished:finished];
}

@end
