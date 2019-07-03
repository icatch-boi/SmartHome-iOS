//
//  SHH264StreamParameter.cpp
//  SmartHome
//
//  Created by ZJ on 2017/4/17.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#include "SHH264StreamParameter.hpp"

SHH264StreamParameter::SHH264StreamParameter(int width, int height, int bitrate, int framerate, int quality) {
    this->width = width;
    this->height = height;
    this->bitrate = bitrate;
    this->framerate = framerate;
    this->quality = quality;
}

string SHH264StreamParameter::getCmdLineParam() {
    char temp[32];
    sprintf(temp, "%d", width);
    string w(temp);
    
    sprintf(temp, "%d", height);
    string h(temp);
    
    sprintf(temp, "%d", bitrate);
    string br(temp);
    
    sprintf(temp, "%d", framerate);
    string fps1(temp);
    
    sprintf(temp, "%d", quality);
    string Q(temp);
    
    int bidirection_audio = 0;
    BOOL pushToTalk = [[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"];
    if (pushToTalk) {
        bidirection_audio = 0;
    } else {
        bidirection_audio = 1;
    }
    sprintf(temp, "%d", bidirection_audio);
    string bid_audio(temp);
    
    string url = "/pv/H264?W="+w+"&H="+h+"&BR="+br+"&FPS="+fps1+"&bidirection_audio="+bid_audio+"&quality="+Q+"&";
    printf("%s\n", url.c_str());
    return url;
}

int SHH264StreamParameter::getVideoWidth() {
    return width;
}

int SHH264StreamParameter::getVideoHeight() {
    return height;
}
