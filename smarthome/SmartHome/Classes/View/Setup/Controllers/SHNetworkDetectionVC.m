//
//  SHNetworkDetectionVC.m
//  SmartHome
//
//  Created by ZJ on 2017/12/13.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHNetworkDetectionVC.h"
#import "SHWiFiSetupVC.h"
#import "SHCheckIndicator.h"
#import "Reachability.h"
//#import "MeasurNetTools.h"
#import "QBTools.h"
#import "SimplePing.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

static int const totalCheckTime = 10;

@interface SHNetworkDetectionVC () <SimplePingDelegate>

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet SHCheckIndicator *networkIndicator;
@property (weak, nonatomic) IBOutlet UILabel *wifiLabel;
@property (weak, nonatomic) IBOutlet UILabel *bandwidthLabel;
@property (weak, nonatomic) IBOutlet UILabel *delayLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UILabel *checkTitleLab;
@property (weak, nonatomic) IBOutlet UILabel *networkTypeLab;
@property (weak, nonatomic) IBOutlet UILabel *networkBandwidthLab;
@property (weak, nonatomic) IBOutlet UILabel *networkDelayLab;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@property (nonatomic) NSTimer *refreshTimer;
@property (nonatomic) CGFloat networkSpeed;
@property (nonatomic, strong, readwrite, nullable)  SimplePing *pinger;
@property (nonatomic, strong, readwrite, nullable)  NSTimer *sendTimer;
@property (strong,nonatomic) NSDate *start;
@property (nonatomic) BOOL pingtimeout; // use for timeout, simpleping do not callback on Timeout.
@property (nonatomic) NSTimeInterval networkLatency;
//@property (nonatomic) MeasurNetTools *measurNet;

@end

@implementation SHNetworkDetectionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupGUI];
    
    [self refreshTimer];
    [self startNetworkSpeedTest];
    [self checkNetworkLatency:@"8.8.8.8"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(totalCheckTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_networkIndicator stopAnimation];
        [self releaseTimer];
        [self stopContinuePing];
        [self updateCheckInfo];
        
        _networkIndicator.titleLabel.text = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"kNetstat", @""), [self networkCheckResult]];
        _nextButton.enabled = YES;
        [self setupButtonBorderColor:_nextButton];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_networkIndicator stopAnimation];
    [self releaseTimer];
    [self stopNetworkSpeedTest];
    [self stopContinuePing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGUI {
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_nextButton setBorderWidth:1.0 borderColor:_nextButton.titleLabel.textColor];
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _titleLabel.text = NSLocalizedString(@"kNetworkEnvironmentDetection", nil);
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    [self setButtonTitle:_skipButton title:NSLocalizedString(@"kSkip", nil)];
    [self setButtonTitle:_nextButton title:NSLocalizedString(@"kNext", nil)];
    _checkTitleLab.text = NSLocalizedString(@"kNetworkCheckTitle", nil);
    _networkTypeLab.text = NSLocalizedString(@"kNetworkTypeDetection", nil);
    _networkBandwidthLab.text = NSLocalizedString(@"kNetworkBandwidthDetection", nil);
    _networkDelayLab.text = NSLocalizedString(@"kNetworkDelayDetection", nil);
    _wifiLabel.text = NSLocalizedString(@"kTesting3", nil);
    _bandwidthLabel.text = NSLocalizedString(@"kTesting3", nil);
    _delayLabel.text = NSLocalizedString(@"kTesting3", nil);
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (void)setupButtonBorderColor:(UIButton *)btn {
    btn.layer.borderColor = btn.titleLabel.textColor.CGColor;
}

- (IBAction)skipClick:(id)sender {
    [_networkIndicator stopAnimation];
    [self releaseTimer];
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2WiFiSetupSegue"]) {
        SHWiFiSetupVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
    } else if ([segue.identifier isEqualToString:@"go2WiFiSetupVCSegue"]) {
        SHWiFiSetupVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
    }
}

- (NSTimer *)refreshTimer {
    if (_refreshTimer == nil) {
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCheckInfo) userInfo:nil repeats:YES];
    }
    
    return _refreshTimer;
}

- (void)releaseTimer {
    [_refreshTimer invalidate];
    _refreshTimer = nil;
}

- (void)updateCheckInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        _wifiLabel.text = [self checkNetworkStatus];
        _bandwidthLabel.text = [NSString stringWithFormat:@"%@/s", [QBTools formattedFileSize:_networkSpeed]];
        _delayLabel.text = [NSString stringWithFormat:@"%.2f ms", _networkLatency];
    });
}

- (NSString *)checkNetworkStatus {
    NSString *str = nil;
    NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    switch (status) {
        case NotReachable:
            str = @"No Internet";
            break;
            
        case ReachableViaWiFi:
            str = @"WiFi";
            break;
            
        case ReachableViaWWAN:
//            str = @"WWAN";
            str = [@"WWAN: " stringByAppendingString:[self getWWANNetType]];
            break;
    }

    return str;
}

- (NSString *)getWWANNetType
{
    NSString *netconnType = nil;
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSString *currentStatus = info.currentRadioAccessTechnology;
    
    if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
        netconnType = @"GPRS";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
        netconnType = @"2.75G EDGE";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){
        netconnType = @"3G";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){
        netconnType = @"3.5G HSDPA";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){
        netconnType = @"3.5G HSUPA";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){
        netconnType = @"2G";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){
        netconnType = @"3G";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){
        netconnType = @"3G";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){
        netconnType = @"3G";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]){
        netconnType = @"HRPD";
    } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){
        netconnType = @"4G";
    }
    
    return netconnType;
}

- (void)startNetworkSpeedTest {
#if 0
    _measurNet = [[MeasurNetTools alloc] initWithblock:^(float speed) {
        _networkSpeed = speed;
    } finishMeasureBlock:^(float speed) {
        _networkSpeed = speed;
        NSString* speedStr = [NSString stringWithFormat:@"%@/S", [QBTools formattedFileSize:speed]];
        NSLog(@"平均速度为：%@",speedStr);
        NSLog(@"相当于带宽：%@",[QBTools formatBandWidth:speed]);
    } failedBlock:^(NSError *error) {
        
    }];
    
    [_measurNet startMeasur];
#endif
}

- (void)stopNetworkSpeedTest {
//    [_measurNet stopMeasur];
}

#pragma mark - latency
- (void)checkNetworkLatency:(NSString *)ipaddress {
    self.pinger =  [[SimplePing alloc] initWithHostName:ipaddress];
    self.pinger.addressStyle = SimplePingAddressStyleICMPv4;
    self.pinger.delegate = self;
    [self.pinger start];
}

- (void)stopContinuePing {
    [self.sendTimer invalidate];
    //self.sendTimer = nil;
    self.pinger = nil;
    //[self dismissViewControllerAnimated:YES completion:nil];
    self.pingtimeout = NO;
}

- (void)sendPing {
    if(self.pingtimeout == YES){
    }
    assert(self.pinger != nil);
    [self.pinger sendPingWithData:nil];
    // check timeout
    self.pingtimeout = YES;
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
#pragma unused(pinger)
    assert(pinger == self.pinger);
    assert(address != nil);
    
    //NSLog(@"pinging %@", [self displayAddressForAddress:address]);
    
    // Send the first ping straight away.
    [self sendPing];
    
    // And start a timer to send the subsequent pings.
    //assert(self.sendTimer == nil);
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error {
    self.pingtimeout = NO;
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
#pragma unused(pinger)
    self.pingtimeout = NO;
    assert(pinger == self.pinger);
    //NSLog(@"failed: %@", shortErrorFromError(error));
    
    [self.sendTimer invalidate];
    //self.sendTimer = nil;
    // No need to call -stop.  The pinger will stop itself in this case.
    // We do however want to nil out pinger so that the runloop stops.
    self.pinger = nil;
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber{
    self.start = [NSDate date];
    self.pingtimeout = NO;
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber {
    self.pingtimeout = NO;
#pragma unused(pinger)
    assert(pinger == self.pinger);
#pragma unused(packet)
    NSLog(@"#%u received, size=%zu", (unsigned int) sequenceNumber, (size_t) packet.length);
    NSDate *end = [NSDate date];
    //latency = [end timeIntervalSinceDate:self.start];//s
    _networkLatency = ([end timeIntervalSinceReferenceDate] - [self.start timeIntervalSinceReferenceDate]) * 1000;
//    NSString *msg = [NSString stringWithFormat:@"%f",latency];
//    if( latency <= 80 )
//        [self showAlertView:msg withTitle:@"PASS"];
//    else if( latency >80 && latency <=120)
//        [self showAlertView:msg withTitle:@"WARNING"];
//    else
//        [self showAlertView:msg withTitle:@"ERROR"];
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
{
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
    self.pingtimeout = NO;
}

-(void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet{
    self.pingtimeout = NO;
}

- (NSString *)networkCheckResult {
    NSString *result = nil;
    NSString *networkStatus = [self checkNetworkStatus];
    
    if ([networkStatus isEqualToString:@"WiFi"]) {
        if (_networkSpeed >= 2 * pow(1024, 2)) {
            if (_networkLatency <= 60) {
                result = NSLocalizedString(@"kGood", @"");
            } else if (_networkLatency > 60 && _networkLatency <= 120) {
                result = NSLocalizedString(@"kGeneral", @"");
            } else {
                result = NSLocalizedString(@"kBad", @"");
            }
        } else if (_networkSpeed >= pow(1024, 2) && _networkSpeed < 2 * pow(1024, 2)) {
            if ( _networkLatency > 60 && _networkLatency <= 120) {
                result = NSLocalizedString(@"kGeneral", @"");
            } else {
                result = NSLocalizedString(@"kBad", @"");
            }
        } else {
            result = NSLocalizedString(@"kBad", @"");
        }
    } else {
        result = NSLocalizedString(@"kError", @"");
    }
    
    return result;
}

@end
