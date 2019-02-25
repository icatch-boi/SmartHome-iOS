//
//  SHDownloadTableViewCell.m
//  SmartHome
//
//  Created by ZJ on 2017/6/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHDownloadTableViewCell.h"
#import "SHDownloadProgressView.h"
#import "DiskSpaceTool.h"
#import "SHDownloadManager.h"

#define kProcessViewWidth 12
#define kScreenWidth [UIScreen screenWidth]
#define kLeftEdge 18
#define kRightEdge 42

@interface SHDownloadTableViewCell ()

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileSizeLabel;

@property (nonatomic ,assign) CGFloat progressViewY;

@end

@implementation SHDownloadTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.progressViewY = self.center.y - kProcessViewWidth * 0.5;
    SHDownloadProgressView *view= [[SHDownloadProgressView alloc] initWithFrame:CGRectMake(kLeftEdge, self.progressViewY, kScreenWidth - kLeftEdge - kRightEdge, kProcessViewWidth)];

    [view setCornerWithRadius:kProcessViewWidth * 0.5];
    
    view.layer.borderColor=[UIColor orangeColor].CGColor;
    
    view.layer.borderWidth=2;
    //计时条背景色   timing bar background color
    view.backgroundColor=[UIColor lightGrayColor];

    
    //计时条颜色     timing bar  color
    view.timeCountColor=[UIColor yellowColor];
    
    //计时栏颜色     timing lab  color
    view.timeCountLabColor=[UIColor blackColor];
    
    //设置计时栏渐变色  set gradient about TimeCountLab‘Color
    view.isTimeCountLabColorGradient=YES;
    
    //origin Time Frequency      初始时间次数
    view.originTimeFrequency=50;
    
    //total Time Frequency       计时总次数
    view.totalTimeFrequency=50;
    
    //time Interval (Unit：Seconds)    计时间隔 （单位：秒）
    view.timeInterval=0.05;
    
    [self addSubview:view];
    self.progressView = view;
	self.shCamObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:self.file.uid];
    SHLogInfo(SHLogTagAPP, @"--->view: %@", view);
	
	}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSString *fileName = [NSString stringWithFormat:@"%s", _file.f.getFileName().c_str()];
    CGFloat fileNameLength = [fileName sizeWithAttributes:@{NSFontAttributeName:self.fileNameLabel.font}].width;
    
    NSString *fileSize = [DiskSpaceTool humanReadableStringFromBytes:_file.f.getFileSize()];
    CGFloat fileSizeLength = [fileSize sizeWithAttributes:@{NSFontAttributeName:self.fileSizeLabel.font}].width;
    
    CGFloat x = max(fileNameLength, fileSizeLength);
    
    self.progressView.frame = CGRectMake(kLeftEdge + x, self.progressViewY, kScreenWidth - kLeftEdge - kRightEdge - x, kProcessViewWidth);
    
    CGRect timeCountLabFrame = self.progressView.timeCountLab.frame;
    timeCountLabFrame.origin.x = (self.progressView.frame.size.width - timeCountLabFrame.size.width) * 0.5;
    self.progressView.timeCountLab.frame = timeCountLabFrame;
}

- (void)setFile:(SHFile *)file {
    _file = file;
    
    _fileNameLabel.text = [NSString stringWithFormat:@"%s", file.f.getFileName().c_str()];
    _fileSizeLabel.text = [DiskSpaceTool humanReadableStringFromBytes:file.f.getFileSize()];
    
	[self updateProgress:0];
}

- (void)setShCamObj:(SHCameraObject *)shCamObj {
    _shCamObj = shCamObj;
	[self updateProgress:0];
}

- (void)updateProgress:(NSInteger)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressView.timeCountLab.text = [NSString stringWithFormat:@"%.1f%%", progress * 1.0];
        _progressView.showunderView.frame = CGRectMake(0, 0, _progressView.frame.size.width * progress / 100, _progressView.frame.size.height);
    });
}

- (IBAction)cancelClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cancelDownloadHandler:)]) {
        [self.delegate cancelDownloadHandler:self];
    }
}


@end
