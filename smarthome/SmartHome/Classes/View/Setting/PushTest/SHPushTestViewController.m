//
//  ViewController.m
//  ICatchPushChart
//
//  Created by ZJ on 2018/10/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHPushTestViewController.h"
#import "XYChart.h"
#import "XYChartItem.h"
#import "SHChartGroup.h"
#import "SHNetworkManager+SHPush.h"
#import "AppDelegate.h"

static NSInteger kPushNum = 20;
static const NSInteger kTimeout = 5;
static NSTimeInterval kPushInterval = 1.0;
static const NSInteger kChartBarWidthOfRow = 20;

@interface SHPushTestViewController () <XYChartDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource>

@property (nonatomic, strong) XYChart *chartView;
@property (nonatomic, strong) SHChartGroup *dataSource;
@property (nonatomic, assign) NSInteger pushCount;
@property (nonatomic, strong) NSTimer *pushTimer;

@property (weak, nonatomic) IBOutlet UIButton *pushButton;
@property (weak, nonatomic) IBOutlet UITextField *pushNumField;
@property (weak, nonatomic) IBOutlet UILabel *pushResultLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *selectPickerView;
@property (weak, nonatomic) IBOutlet UITableView *resultTableView;
@property (weak, nonatomic) IBOutlet UISwitch *quiesceSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *slideSwitch;

@property (nonatomic, strong) NSArray<NSDictionary *> *resultArray;

@property (nonatomic, weak) AppDelegate *delegate;
@property (nonatomic, assign) BOOL startPushTest;
@property (nonatomic, strong) NSString *cameraUid;
@property (nonatomic, assign) SHPushType pushType;

@end

@implementation SHPushTestViewController

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupGUI];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kPushTest"];
}

- (void)setupGUI {
    self.pushNumField.delegate = self;

    self.selectPickerView.delegate = self;
    self.selectPickerView.dataSource = self;
    
    [self.selectPickerView selectRow:kPushNum - 1 inComponent:0 animated:YES];
    [self.selectPickerView selectRow:kPushInterval - 1 inComponent:1 animated:YES];
    [self.selectPickerView selectRow:kTimeout - 1 inComponent:2 animated:YES];
    
    self.resultTableView.dataSource = self;
    self.resultTableView.rowHeight = 32;
    
    self.quiesceSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"kQuiesce"];
    self.slideSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"kSlideChart"];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:self action:@selector(close) isBack:NO];
    
    self.cameraUid = self.navigationController.title;
    self.cameraUid = self.cameraUid ? self.cameraUid : @"7NAHPFBRJRJVKHKX111A";
    
    self.title = @"Push Test";
}

- (void)close {
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.isFullScreenPV = NO;
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [SHTool setupCurrentFullScreen:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self releasePushTimer];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"kPushTest"];
}

- (NSArray<NSString *> *)prepareChartData:(NSArray *)recvMsg {
    NSInteger row = kPushNum;
    
    NSMutableArray<NSString *> *item = [NSMutableArray arrayWithCapacity:row];
    for (int i = 0; i < row; i++) {
        [item addObject:@""];
    }
    
    [recvMsg enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [obj[@"msgID"] integerValue];
        
        if (index < kPushNum) {
            double delay = [obj[@"client"] doubleValue] - [obj[@"device"] doubleValue];
            delay *= 1000;
            
            SHLogInfo(SHLogTagAPP, @"index: %ld, delay: %f, obj: %@", (long)index, delay, obj);
            
            NSString *temp = [NSString stringWithFormat:@"%ld %f", (long)index + 1, delay];
            if (temp != nil) {
                [item replaceObjectAtIndex:index withObject:temp];
            }
        }
    }];
    
    return item.copy;
}

- (void)drawChartViewWithMessages:(NSArray *)recvMsg {
    if (self.startPushTest == NO) {
        return;
    }
    
    NSArray<NSArray<NSString *>*> *dataList = @[
                                                [self prepareChartData:recvMsg],
                                                ];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.chartView removeFromSuperview];

        self.dataSource = [[SHChartGroup alloc] initWithStyle:XYChartTypeLine section:1 row:kPushNum dataList:dataList];
        self.dataSource.range = XYRangeMake(0, 3000);
        
        CGFloat width = self.view.frame.size.width - 20;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kSlideChart"]) {
            self.dataSource.widthOfRow = kChartBarWidthOfRow;
            
            self.dataSource.autoSizingRowWidth = NO;
            if (kPushNum * kChartBarWidthOfRow < width) {
                self.dataSource.autoSizingRowWidth = YES;
            }
        }

        CGFloat navBarHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
        CGFloat scale = CGRectGetHeight(self.view.frame) / 320.0;
        CGFloat height = (205 - navBarHeight) * scale;
        self.chartView = [[XYChart alloc] initWithFrame:CGRectMake(6, navBarHeight + 5, width, height)
                                          chartType:XYChartTypeBar];
        self.chartView.dataSource = self.dataSource;
        self.chartView.delegate = self;

        [self.view addSubview:self.chartView];
        
        NSString *msgInfo = [NSString stringWithFormat:@"recv: %lu, total: %ld", (unsigned long)recvMsg.count, (long)kPushNum];
        self.pushResultLabel.text = msgInfo;
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resultHandler:(NSArray *)recvMsg {
    NSArray<NSString *> *result = [self prepareChartData:recvMsg];
    NSMutableArray<NSNumber *> *notRecv = [NSMutableArray array];
    NSMutableArray<NSNumber *> *delay = [NSMutableArray array];
    
    [result enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@""]) {
            [notRecv addObject:@(idx)];
        } else {
            NSArray<NSString *> *temp = [obj componentsSeparatedByString:@" "];
            [delay addObject:@(temp.lastObject.integerValue)];
        }
    }];
    
    __block NSInteger min = delay.firstObject.integerValue;
    __block NSInteger max = delay.firstObject.integerValue;
    __block NSInteger sum = 0;
    [delay enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger temp = obj.integerValue;
        
        min = MIN(temp, min);
        max = MAX(temp, max);
        
        sum += temp;
    }];
    
    SHLogInfo(SHLogTagAPP, @"delay max: %ld, min: %ld, sum: %ld", max, min, sum);
    SHLogInfo(SHLogTagAPP, @"not receive count: %ld \n --> %@", notRecv.count, notRecv);
    
    CGFloat successCount = kPushNum - notRecv.count;
    CGFloat sendRate = successCount / kPushNum;

    SHLogInfo(SHLogTagAPP, @"successfully send rate: %f", sendRate);
    
    CGFloat averageDelay = delay.count > 2 ? (CGFloat)(sum - max - min) / (delay.count - 2) : (CGFloat)sum  / delay.count;
    SHLogInfo(SHLogTagAPP, @"average Delay: %f", averageDelay);
    
    self.resultArray = @[
                        @{@"未收到": [NSString stringWithFormat:@"%ld 条", notRecv.count]},
                        @{@"送达率": [NSString stringWithFormat:@"%.1f%%", sendRate * 100]},
                        @{@"平均延时": [NSString stringWithFormat:@"%.3fs", averageDelay / 1000.0]},
                        @{@"Max(Min)": [NSString stringWithFormat:@"%.3fs,%.3fs", max / 1000.0, min / 1000.0]},
                        ];
    
    [self.resultTableView reloadData];
}

- (NSString *)splitString:(NSArray<NSNumber *> *)notReceived {
    NSMutableString *str = [[NSMutableString alloc] init];
    
    [notReceived enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([str isEqualToString:@""]) {
            [str appendString:obj.stringValue];
        } else {
            [str appendString:@";"];
            [str appendString:obj.stringValue];
        }
    }];
    
    if ([str isEqualToString:@""]) {
        [str appendString:@"无"];
    }
    
    return str;
}

- (IBAction)startPushClick:(UIButton *)sender {
    self.pushResultLabel.text = @"实时 push 结果";

    if (self.startPushTest) {
        [self stopPushTestHandler];
        self.startPushTest = NO;
    } else {
        [self startPushTestHandler];
        self.startPushTest = YES;
    }
}

- (void)startPushTestHandler {
    [self setUIEnable:NO];
    self.resultArray = nil;
    [self.resultTableView reloadData];
    
    if (![self.pushNumField.text isEqualToString:@""]) {
        NSInteger pushNum = self.pushNumField.text.integerValue;
        SHLogInfo(SHLogTagAPP, @"enter push num: %ld", (long)pushNum);
        
        kPushNum = pushNum > 0 ? pushNum : kPushNum;
        
        SHLogInfo(SHLogTagAPP, @"reality push num: %ld", (long)kPushNum);
    }
    
    [self.delegate cleanMessageCache];
    
    [self pushTimer];
}

- (void)stopPushTestHandler {
    [self releasePushTimer];

    [self setUIEnable:YES];
    self.pushCount = 0;
    [self.delegate cleanMessageCache];
}

- (void)updatePushButtonState {
    NSString *btnTitle = self.startPushTest ? @"Stop Push" : @"Start Push";
    
    [self.pushButton setTitle:btnTitle forState:UIControlStateNormal];
}

- (void)setStartPushTest:(BOOL)startPushTest {
    _startPushTest = startPushTest;
    [self updatePushButtonState];
}

- (void)pushMessageHelper {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    SHLogInfo(SHLogTagAPP, @"start push message");
        NSDate *date = [NSDate date];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *time = [formatter stringFromDate:date];
        
        NSDictionary *temp = @{
                               @"msgID": @(self.pushCount).stringValue,
                               @"devID": self.cameraUid,
                               @"time": time,
                               @"msgType": @204,
                               @"msgParam": @"",
                               @"tmdbg": @(date.timeIntervalSince1970).stringValue,
                               };
    
    if (temp == nil) {
        SHLogError(SHLogTagAPP, @"error: temp is nil.");
        self.pushCount--;
        return;
    }
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:temp options:NSJSONWritingPrettyPrinted error:nil];
        NSString *msg = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        msg =  [msg stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
        [[SHNetworkManager sharedNetworkManager] pushMessageWithUID:self.cameraUid message:msg pushType:self.pushType finished:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"push message success: %d", isSuccess);
            
            NSArray *messages = self.delegate.messages;
            [self drawChartViewWithMessages:messages.copy];
        }];
//    });
}

- (void)pushCompletionHandler {
    if (self.pushCount >= kPushNum) {
        [self releasePushTimer];
        
        NSArray *messages = self.delegate.messages;
        NSTimeInterval start = [NSDate date].timeIntervalSince1970;
        
        while (messages.count != kPushNum) {
            
            NSTimeInterval end = [NSDate date].timeIntervalSince1970;
            if (end - start > kTimeout) {
                SHLogWarn(SHLogTagAPP, @"recv timeout, current recv: %lu message.", (unsigned long)messages.count);
                break;
            }
            
            [NSThread sleepForTimeInterval:kPushInterval];
            messages = self.delegate.messages;
        }
        
//        NSLog(@"recv message: %@\n total: %lu", messages, (unsigned long)messages.count);
        [self drawChartViewWithMessages:messages.copy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUIEnable:YES];
            self.pushCount = 0;
            
            [self resultHandler:messages.copy];
            self.startPushTest = NO;
        });
    }
}

- (void)pushMessage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self pushMessageHelper];
        
        self.pushCount++;
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self pushCompletionHandler];
//        });
        
        [self pushCompletionHandler];
    });
}

- (NSTimer *)pushTimer {
    if (_pushTimer == nil) {
        _pushTimer = [NSTimer scheduledTimerWithTimeInterval:kPushInterval target:self selector:@selector(pushMessage) userInfo:nil repeats:YES];
    }
    
    return _pushTimer;
}

- (void)releasePushTimer {
    if ([_pushTimer isValid]) {
        [_pushTimer invalidate];
        _pushTimer = nil;
    }
}

#pragma mark - XYChartDataSource
- (NSUInteger)numberOfSectionsInChart:(XYChart *)chart {
    return 1;
}

- (NSUInteger)numberOfRowsInChart:(XYChart *)chart {
    return 5;
}

- (NSAttributedString *)chart:(XYChart *)chart titleOfRowAtIndex:(NSUInteger)index {
    return [[NSMutableAttributedString alloc] initWithString:@"x轴"
                                           attributes:
     @{
       NSFontAttributeName: [UIFont systemFontOfSize:10],
       NSForegroundColorAttributeName: [UIColor xy_random],
       }];
}

- (NSAttributedString *)chart:(XYChart *)chart titleOfSectionAtValue:(CGFloat)sectionValue {
    return [[NSMutableAttributedString alloc] initWithString:@"y轴"
                                                  attributes:
            @{
              NSFontAttributeName: [UIFont systemFontOfSize:10],
              NSForegroundColorAttributeName: [UIColor xy_random],
              }];
}

- (id<XYChartItem>)chart:(XYChart *)chart itemOfIndex:(NSIndexPath *)index {
    XYChartItem *item = [[XYChartItem alloc] init];
    NSInteger v = index.row * 10;
    item.value = @(v);
    item.color = [UIColor xy_random];
    item.duration = 0.3;
    item.showName = [NSString stringWithFormat:@"%ld", v];
    
    return item;
}

- (XYRange)visibleRangeInChart:(XYChart *)chart {
    return XYRangeMake(0, 50);
}

- (NSUInteger)numberOfLevelInChart:(XYChart *)chart {
    return 5;
}

- (CGFloat)rowWidthOfChart:(XYChart *)chart {
    return 60;
}

- (BOOL)autoSizingRowInChart:(XYChart *)chart {
    return YES;
}

#pragma mark - XYChartDelegate
- (BOOL)chart:(XYChart *)chart shouldShowMenu:(NSIndexPath *)index {
    return NO;
}

- (void)chart:(XYChart *)chart itemDidClick:(id<XYChartItem>)item {
    
}

- (CAAnimation *)chart:(XYChart *)chart clickAnimationOfIndex:(NSIndexPath *)index {
    return nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    int row = 0;
    
    switch (component) {
        case 0:
            row = 100;
            break;
            
        case 1:
            row = 10;
            break;
            
        case 2:
            row = 2;
            break;
            
        default:
            break;
    }
    
    return row;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = [NSString stringWithFormat:@"%ld%@", (long)row + 1, component ? @"s" : @"次"];
    if (component == 2) {
        title = row == 0 ? @"Our" : @"Other";
    }
    
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSInteger value = row + 1;
    if (component == 0) {
        kPushNum = value;
    } else if (component == 1) {
        kPushInterval = value;
    } else if (component == 2) {
        self.pushType = row == 0 ? SHPushTypeOur : SHPushTypeOther;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *pickerLabel = (UILabel *)view;
    if (!pickerLabel) {
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.textColor = [self pickerViewColor:component]; //[UIColor whiteColor];
        pickerLabel.textAlignment = NSTextAlignmentCenter;
        pickerLabel.font = [UIFont systemFontOfSize:20.0f];
    }
    pickerLabel.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    
    return pickerLabel;
}

- (UIColor *)pickerViewColor:(NSInteger)component {
    UIColor *color = nil;
    
    switch (component) {
        case 0:
            color = [UIColor redColor];
            break;
            
        case 1:
            color = [UIColor greenColor];
            break;
            
        case 2:
            color = [UIColor blueColor];
            break;
            
        default:
            color = [UIColor whiteColor];
            break;
    }
    
    return color;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"resultCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"resultCell"];
    }
    
    cell.textLabel.text = self.resultArray[indexPath.row].allKeys.firstObject;
    cell.detailTextLabel.text = self.resultArray[indexPath.row][cell.textLabel.text];
    
    if (indexPath.row == self.resultArray.count - 1) {
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    }
    
    return cell;
}

- (IBAction)switchClick:(UISwitch *)sender {
    if (sender.tag == 0) {  //静默
        [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"kQuiesce"];
    } else if (sender.tag == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"kSlideChart"];
    }
}

- (void)setUIEnable:(BOOL)enable {
//    self.pushButton.enabled = enable;
    self.resultTableView.userInteractionEnabled = enable;
    self.quiesceSwitch.enabled = enable;
    self.slideSwitch.enabled = enable;
    self.selectPickerView.userInteractionEnabled = enable;
}

- (AppDelegate *)delegate {
    if (_delegate == nil) {
        _delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    }
    
    return _delegate;
}

@end
