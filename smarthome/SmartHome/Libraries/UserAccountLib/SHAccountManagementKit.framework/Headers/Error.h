// Error.h

/**************************************************************************
 *
 *       Copyright (c) 2014-2018 by iCatch Technology, Inc.
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
 
 // Created by guo on 01/03/2018 14:54.
    

#import <Foundation/Foundation.h>

@interface Error : NSObject
@property(nonatomic, readonly) NSInteger error_code;
@property(nonatomic, readonly) NSString * _Nonnull name;
@property(nonatomic, readonly) NSString * _Nonnull error;
@property(nonatomic, readonly) NSString * _Nonnull error_description;

//-(instancetype _Nonnull )initWithData:(NSDictionary * _Nonnull )dict;

-(instancetype _Nonnull )initWithErrorCode:(NSInteger)error_code
                                   andName:(NSString *_Nullable)name
                                  andError:(NSString *_Nullable)error
                       andErrorDescription:(NSString *_Nullable)error_description;

+(instancetype _Nullable)errorWithNSError:(NSError *_Nonnull)error;
@end
