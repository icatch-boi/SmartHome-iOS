//
//  SHH264StreamParameter.hpp
//  SmartHome
//
//  Created by ZJ on 2017/4/17.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#ifndef SHH264StreamParameter_hpp
#define SHH264StreamParameter_hpp

#include <stdio.h>

class SHH264StreamParameter:public ICatchStreamParam {
public:
    SHH264StreamParameter(int width, int height, int bitrate, int framerate);
    string getCmdLineParam();
    int getVideoWidth();
    int getVideoHeight();
    
private:
    int width, height, bitrate, framerate;
};

#endif /* SHH264StreamParameter_hpp */
