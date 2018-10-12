//
//  SHCameraControlCenter.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHCommonControl.h"
#import "SHActionControl.h"
#import "SHPropertyControl.h"
#import "SHFileControl.h"
#import "SHPlaybackControl.h"

@interface SHControlCenter : NSObject

#pragma mark - Controler
@property (nonatomic) SHCommonControl *comCtrl;
@property (nonatomic) SHPropertyControl*propCtrl;
@property (nonatomic) SHActionControl *actCtrl;
@property (nonatomic) SHFileControl *fileCtrl;
@property (nonatomic) SHPlaybackControl *pbCtrl;

- (instancetype)initWithParameters:(SHCommonControl *)nComCtrl
                andPropertyControl:(SHPropertyControl *)nPropCtrl
                  andActionControl:(SHActionControl *)nActCtrl
                    andFileControl:(SHFileControl *)nFileCtrl
                andPlaybackControl:(SHPlaybackControl *)nPBCtrl;

@end
