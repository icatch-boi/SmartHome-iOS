//
//  MpbSDKEventListener.cpp
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-13.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#include "MpbSDKEventListener.h"

void MpbSDKEventListener::eventNotify(ICatchEvent* icatchEvt) {}

MpbSDKEventListener::MpbSDKEventListener(SHVideoPlaybackVC *controller) {
  this->controller = controller;
}

void MpbSDKEventListener::updateVideoPbProgress(ICatchEvent* icatchEvt) {
  if (icatchEvt) {
    [controller updateVideoPbProgress:icatchEvt->getDoubleValue1() ];
  }
}

void MpbSDKEventListener::updateVideoPbProgressState(ICatchEvent* icatchEvt) {
  if (icatchEvt) {
    if (icatchEvt->getIntValue1() == 1) {
      SHLogInfo(SHLogTagAPP, @"I received an event: Pause");
      [controller updateVideoPbProgressState:YES];
    } else if (icatchEvt->getIntValue1() == 2) {
      SHLogInfo(SHLogTagAPP, @"I received an event: Resume");
      [controller updateVideoPbProgressState:NO];
    }
  }
}

void MpbSDKEventListener::stopVideoPb(ICatchEvent* icatchEvt) {
  SHLogInfo(SHLogTagAPP, @"I received an event: *Playback done");
  [controller stopVideoPb];
}

void MpbSDKEventListener::showServerStreamError(ICatchEvent *icatchEvt) {
  SHLogInfo(SHLogTagAPP, @"I received an event: *Server Stream Error: %f,%f,%f", icatchEvt->getDoubleValue1(), icatchEvt->getDoubleValue2(), icatchEvt->getDoubleValue3());
  [controller showServerStreamError];
}
