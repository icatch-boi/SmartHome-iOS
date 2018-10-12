//
//  SHUserAccountCell.h
//  SHAccountsManagement
//
//  Created by ZJ on 2018/3/5.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SHUserAccountCellProtocol <NSObject>
-(void)sendCheckEmailValidCommand;
@end
@interface SHUserAccountCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (weak, nonatomic) IBOutlet UITextField *surepwdTextField;
@property (weak, nonatomic) IBOutlet UITextField *verifycodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *getVerifycodeBtn;

@property (weak, nonatomic) id<SHUserAccountCellProtocol> delegate;

@end
