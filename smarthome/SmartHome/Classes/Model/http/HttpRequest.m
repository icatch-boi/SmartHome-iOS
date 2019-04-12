//
//  HttpRequest.m
//  SmartHome
//
//  Created by yh.zhang on 2017/10/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "HttpRequest.h"

@implementation HttpRequest
+ (BOOL)getSyncWithUrl:(NSString *)url {
	NSLog(@"http request:get, url is :%@",url);
	NSURL *url1 = [NSURL URLWithString:url];
	//通过URL创建网络请求
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url1 cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	
	NSURLResponse *response;
	NSError *error;
	//连接服务器
	NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	NSHTTPURLResponse *response1 = (NSHTTPURLResponse*)response;
	if(response1.statusCode != 200){
		NSLog(@"error http request url is :%@",url);
		return NO;
	}
    
	NSString *str = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
	NSLog(@"receive is :%@",str);
    
    return YES;
}

+ (void) postSyncWithUrl:(NSString *)url :(NSString *)jsonData{
	NSLog(@"send url is :%@",url);
	NSLog(@"send json is :%@",jsonData);
	
	NSURL *url1 = [NSURL URLWithString:url];
	//创建请求
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url1 cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
	[request setHTTPMethod:@"POST"];//设置请求方式为POST，默认为GET
	
	NSData *data = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:data];
	//连接服务器
	NSURLResponse *response;
	NSError *error;
	
	NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	NSHTTPURLResponse *response1 = (NSHTTPURLResponse*)response;
	if(response1.statusCode != 200){
		NSLog(@"error http request url is :%@",url);
		return;
	}
	
	NSString *str1 = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
	
	NSLog(@"%@",str1);
}

@end
