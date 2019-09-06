// SHSubscriberCell.m

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
 
 // Created by zj on 2019/7/23 5:51 PM.
    

#import "SHSubscriberCell.h"
#import "SHNetworkManagerHeader.h"
#import "SVProgressHUD.h"
#import "SHUserAccountCommon.h"
#import "SHSubscriberInfo.h"
#import "SDWebImageManager.h"

static const CGFloat kAvatarWidth = 36.0;
static const CGFloat kDeleteButtonHeight = 40.0;
static const CGFloat kMargin = 16.0;

@interface SHSubscriberCell ()

@property (nonatomic, weak) UIButton *deleteButton;

@end
@implementation SHSubscriberCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        UIButton *deleteButton = [[UIButton alloc] init];
        
        [deleteButton setImage:[UIImage imageNamed:@"btn-delect"] forState:UIControlStateNormal];
        [deleteButton setImage:[UIImage imageNamed:@"btn-delect-pre"] forState:UIControlStateNormal];

        [deleteButton addTarget:self action:@selector(removeSubscriberClick) forControlEvents:UIControlEventTouchUpInside];
        
        [self.contentView addSubview:deleteButton];
        
        self.deleteButton = deleteButton;
        
        self.textLabel.textColor = [UIColor ic_colorWithHex:kTextColor];
        self.detailTextLabel.textColor = [UIColor ic_colorWithHex:kTextColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImage *defaultImage = [UIImage imageNamed:@"portrait"];
        self.imageView.image = [defaultImage ic_cornerImageWithSize:CGSizeMake(kAvatarWidth, kAvatarWidth) radius:kAvatarWidth * 0.5];
    }
    
    return self;
}

- (void)removeSubscriberClick {
    if ([self.delegate respondsToSelector:@selector(subscriberCellDidClickDeleteButton:)]) {
        [self.delegate subscriberCellDidClickDeleteButton:self];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSubscriber:(SHSubscriberInfo *)subscriber {
    _subscriber = subscriber;
    
    (subscriber.accout == nil) ? [self acquireAccountInfo] : [self setupAccountInfo];
    
    self.detailTextLabel.text = [SHUserAccountCommon dateTransformFromString:subscriber.subscriber.time];
}

- (void)setupAvatar {
    NSURL *url = [NSURL URLWithString:self.subscriber.accout.portrait];
    
    WEAK_SELF(self);
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                UIImage *tempImage = [image ic_cornerImageWithSize:CGSizeMake(kAvatarWidth, kAvatarWidth) radius:kAvatarWidth * 0.5];
                
                weakself.imageView.image = tempImage;
            }
        });
    }];
}

- (void)setupAccountInfo {
    self.textLabel.text = self.subscriber.accout.name;
//    [self setupAvatar];
}

- (void)acquireAccountInfo {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];
    
    WEAK_SELF(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        [[SHNetworkManager sharedNetworkManager] acquireAccountInfoWithUserID:_subscriber.subscriber.userId completion:^(BOOL isSuccess, id  _Nonnull result) {
            SHLogInfo(SHLogTagAPP, @"acquireAccountInfo is success: %d", isSuccess);
            
            STRONG_SELF(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                
                if (isSuccess) {
                    Account *account = result;
                    
                    self.subscriber.accout = account;
                    
                    [self setupAccountInfo];
                } else {
                    Error *error = result;
                    SHLogError(SHLogTagAPP, @"acquireAccountInfo failed: %@", error.error_description);
                }
            });
        }];
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat btnH = MIN(kDeleteButtonHeight, height);
    CGFloat btnW = btnH;
    CGFloat btnX = CGRectGetWidth(self.bounds) - kMargin - btnW;
    CGFloat btnY = (height - btnH) * 0.5;
    self.deleteButton.frame = CGRectMake(btnX, btnY, btnW, btnH);
    
    self.imageView.center = CGPointMake(self.imageView.center.x, self.deleteButton.center.y);
}

@end
