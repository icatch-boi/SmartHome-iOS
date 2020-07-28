//
//  FRDFaceInfoViewModel.h
//  FaceRecognition
//
//  Created by ZJ on 2018/9/17.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRDFaceInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^FaceInfoViewModelCompletion)(void);

@interface FRDFaceInfoViewModel : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<FRDFaceInfo *> *facesInfoArray;

- (void)loadFacesInfoWithCompletion:(FaceInfoViewModelCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
