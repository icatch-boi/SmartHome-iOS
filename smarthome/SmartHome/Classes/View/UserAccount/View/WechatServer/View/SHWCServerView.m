// SHWCServerView.m

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
 
 // Created by zj on 2019/2/11 3:26 PM.
    

#import "SHWCServerView.h"

@implementation SHWCServerView

+ (instancetype)wcserverView {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    SHWCServerView *v = [nib instantiateWithOwner:nil options:nil].firstObject;
    v.frame = [UIScreen mainScreen].bounds;
    
    return v;
}

- (IBAction)unlinkClick:(id)sender {
    SHLogTRACE();
}

@end
