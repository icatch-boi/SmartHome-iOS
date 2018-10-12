// SubscribeStatus.h

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by sa on 2018/5/11 上午10:57.
    

#ifndef SubscribeStatus_h
#define SubscribeStatus_h

enum SubscribeStatus {

	APP_HOST_SUBSCRIBING = 273,
	APP_HOST_SUBSCRIBE_INVLID = 529,
	APP_HOST_WAIT_USER_CONFIRM = 785,
	
	APP_USER_SUBSCRIBING = 289,
	APP_USER_SUBSCRIBE_INVLID = 545,
	APP_USER_WAIT_HOST_CONFIRM = 801,
	
	APP_HOST_REMOVE_USER = 305,
	APP_HOST_REMOVE_USER_INVALID = 561,
	APP_HOST_REMOVE_NO_CONFIRM_USER = 817,
	
	APP_USER_REMOVE_SUBSCRIBE = 321,
	APP_USER_REMOVE_INVALID_SUBSCRIBE = 577,
    APP_USER_REMOVE_REFUSE_SUBSCRIBE = 833,
};
#endif /* SubscribeStatus_h */
