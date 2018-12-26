//
//  SHLoginView.m
//  SHAccountsManagement
//
//  Created by ZJ on 2018/3/5.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHLoginView.h"
#import "SHUserAccountCell.h"

static NSString * const kEmailCellID = @"emailReuseID";
static NSString * const kPasswordCellID = @"passwordReuseID";
static NSString * const kSurePasswordCellID = @"surePasswordReuseID";

@interface SHLoginView () <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatorImgView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logonButton;
@property (weak, nonatomic) IBOutlet UIButton *forgetPWDButton;

@end

@implementation SHLoginView

+ (instancetype)loginView {
    UINib *nib = [UINib nibWithNibName:@"SHLoginView" bundle:nil];
    SHLoginView *view = [nib instantiateWithOwner:nil options:nil][0];
    view.frame = [[UIScreen mainScreen] bounds];
    SHLogInfo(SHLogTagAPP, @"frame: %@", NSStringFromCGRect(view.frame));
    
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupGUI];
}

- (void)setupGUI {
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"emailCell" bundle:nil] forCellReuseIdentifier:kEmailCellID];
    [self.tableView registerNib:[UINib nibWithNibName:@"passwordCell" bundle:nil] forCellReuseIdentifier:kPasswordCellID];
    
    [_avatorImgView setCornerWithRadius:_avatorImgView.bounds.size.width * 0.5 masksToBounds:NO];
    [_loginButton setCornerWithRadius:_loginButton.bounds.size.height * 0.5 masksToBounds:NO];
}

- (IBAction)loginClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(loginAccount:)]) {
        [self.delegate loginAccount:self];
    }
}

- (IBAction)logonClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(logonAccount:)]) {
        [self.delegate logonAccount:self];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = nil;
    
    if (indexPath.row == 0) {
        cellIdentifier = kEmailCellID;
    } else if (indexPath.row == 1) {
        cellIdentifier = kPasswordCellID;
    }
    
    SHUserAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self getSubViewWithCell:cell indexPath:indexPath];
    
    return cell;
}

- (void)getSubViewWithCell:(SHUserAccountCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        _emailTextField = cell.emailTextField;
#ifdef DEBUG
        _emailTextField.text = @"test1@test.com";
#endif
//        [_emailTextField becomeFirstResponder];
    } else if (indexPath.row == 1) {
        _pwdTextField = cell.pwdTextField;
#ifdef DEBUG
        _pwdTextField.text = @"test1";
#endif
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
