// FaceCollectionViewCell.h

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
 
 // Created by zj on 2019/1/4 3:21 PM.
    

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FaceCollectionViewCell;
@protocol FaceCollectionViewCellDelete <NSObject>

- (void)opertionClickWithFaceCollectionViewCell:(FaceCollectionViewCell *)cell;

@end

@class FRDFaceData;
@interface FaceCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) FRDFaceData *faceData;
@property (nonatomic, weak) id<FaceCollectionViewCellDelete> delegate;

@end

NS_ASSUME_NONNULL_END
