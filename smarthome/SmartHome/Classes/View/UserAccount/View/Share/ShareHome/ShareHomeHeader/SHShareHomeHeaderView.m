//
//  SHShareHomeHeaderView.m
//  SmartHome
//
//  Created by ZJ on 2018/3/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHShareHomeHeaderView.h"

@implementation SHShareHomeHeaderView

+ (instancetype)shareHomwHeaderView:(CGRect)frame {
    UINib *nib = [UINib nibWithNibName:@"SHShareHomeHeaderView" bundle:nil];
    SHShareHomeHeaderView *headerView = [nib instantiateWithOwner:nil options:nil][0];
    headerView.frame = frame;
    
    return headerView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
