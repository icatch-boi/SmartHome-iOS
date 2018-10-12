//
//  SHCameraControlCenter.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHControlCenter.h"

@implementation SHControlCenter

- (instancetype)initWithParameters:(SHCommonControl *)nComCtrl andPropertyControl:(SHPropertyControl *)nPropCtrl andActionControl:(SHActionControl *)nActCtrl andFileControl:(SHFileControl *)nFileCtrl andPlaybackControl:(SHPlaybackControl *)nPBCtrl {
    SHControlCenter *ctrl = [[SHControlCenter alloc] init];
    
    ctrl.comCtrl = nComCtrl;
    ctrl.propCtrl = nPropCtrl;
    ctrl.actCtrl = nActCtrl;
    ctrl.fileCtrl = nFileCtrl;
    ctrl.pbCtrl = nPBCtrl;
    
    return ctrl;
}

@end
