// SHDownloadCell.m

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
 
 // Created by zj on 2019/10/25 4:33 PM.
    

#import "SHDownloadCell.h"

@interface SHDownloadCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *operationButton;

@end

@implementation SHDownloadCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.userInteractionEnabled = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)clickAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(buttonClickedActionWithCell:)]) {
        [self.delegate buttonClickedActionWithCell:self];
    }
}

- (void)setFileInfo:(SHS3FileInfo *)fileInfo {
    _fileInfo = fileInfo;
    
    _nameLabel.text = fileInfo.fileName;
    _sizeLabel.text = [DiskSpaceTool humanReadableStringFromBytes:fileInfo.videosize.integerValue];
    _iconImageView.image = [fileInfo.thumbnail ic_cornerImageWithSize:_iconImageView.bounds.size radius:kImageCornerRadius];
    _statusLabel.text = [self currentDownloadState:fileInfo.downloadState];
}

- (void)setOptionItem:(SHOptionItem *)optionItem {
    _optionItem = optionItem;
    
    if ([optionItem.title isEqualToString:NSLocalizedString(@"kDownloading", nil)]) {
        [_operationButton setImage:[UIImage imageNamed:@"ic_cancel_red_500_24dp"] forState:UIControlStateNormal];
        [_operationButton setImage:[UIImage imageNamed:@"ic_cancel_red_500_24dp"] forState:UIControlStateHighlighted];
    } else {
        [_operationButton setImage:[UIImage imageNamed:@"ic_info_black_24dp"] forState:UIControlStateNormal];
        [_operationButton setImage:[UIImage imageNamed:@"ic_info_black_24dp"] forState:UIControlStateHighlighted];
    }
}

- (NSString *)currentDownloadState:(SHDownloadState)state {
    NSString *stateString = nil;
    
    switch (state) {
        case SHDownloadStateWaiting:
            stateString = NSLocalizedString(@"kWaitDownload", nil);
            break;
            
        case SHDownloadStateDownloading:
            stateString = [NSString stringWithFormat:@"%@...", NSLocalizedString(@"kDownloading", nil)];
            break;
            
        case SHDownloadStateDownloadSuccess:
            stateString = NSLocalizedString(@"kDownloadSuccess", nil);
            break;
            
        case SHDownloadStateDownloadFailed:
            stateString = NSLocalizedString(@"kDownloadFailed", nil);
            break;
            
        case SHDownloadStateCancelDownload:
            stateString = NSLocalizedString(@"kAlreadyCancel", nil);
            break;
            
        default:
            break;
    }
    
    return stateString;
}

@end
