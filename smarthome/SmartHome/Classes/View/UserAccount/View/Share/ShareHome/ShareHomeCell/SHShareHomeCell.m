//
//  SHShareHomeCell.m
//  SmartHome
//
//  Created by ZJ on 2018/3/7.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHShareHomeCell.h"
#import "SHNetworkManagerHeader.h"
#import "SHUserAccountCommon.h"
#import "SubscribeStatus.h"
#import "SHSubscribeInfoConvert.h"
@interface SHShareHomeCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *operateLabel;

@end

@implementation SHShareHomeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSubscriber:(Subscriber *)subscriber {
    _subscriber = subscriber;
    
//    _titleLabel.text = subscriber.userId;
    [self acquireAccountInfo];
    _infoLabel.text = [SHUserAccountCommon dateTransformFromString:subscriber.time];
    _operateLabel.text = statuCodeToString(subscriber.status);
}

- (void)acquireAccountInfo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        [[SHNetworkManager sharedNetworkManager] acquireAccountInfoWithUserID:_subscriber.userId completion:^(BOOL isSuccess, id  _Nonnull result) {
            SHLogInfo(SHLogTagAPP, @"acquireAccountInfo is success: %d", isSuccess);
            
            if (isSuccess) {
                Account *account = result;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _titleLabel.text = account.name;
                });
            } else {
                Error *error = result;
                SHLogError(SHLogTagAPP, @"acquireAccountInfo failed: %@", error.error_description);
            }
        }];
    });
}

@end
