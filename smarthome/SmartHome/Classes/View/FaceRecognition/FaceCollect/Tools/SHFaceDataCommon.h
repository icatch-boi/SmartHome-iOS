// SHFaceDataCommon.h

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
 
 // Created by zj on 2019/7/31 5:36 PM.
    

#ifndef SHFaceDataCommon_h
#define SHFaceDataCommon_h

typedef void(^FaceDataHandleCompletion)(NSDictionary<NSString *, NSNumber *> * _Nullable result);
static const int64_t kWaitTimeout = 15ull * NSEC_PER_SEC;
static const NSTimeInterval kAddFaceMaxInterval = 60; //120;

#endif /* SHFaceDataCommon_h */
