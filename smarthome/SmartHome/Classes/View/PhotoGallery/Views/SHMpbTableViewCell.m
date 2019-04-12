//
//  SHMpbTableViewCell.m
//  SmartHome
//
//  Created by ZJ on 2017/5/4.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHMpbTableViewCell.h"

@interface SHMpbTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *recordTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *recordTypeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *selectedComfirmIcon;
@property (weak, nonatomic) IBOutlet UIImageView *videoStaticIcon;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteIcon;

@end
@implementation SHMpbTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFile:(ICatchFile *)file {
    _file = file;
    
    self.recordTimeLabel.text = [self translateDate:file->getFileTime()];
    self.lengthLabel.text = [NSString translateSecsToString1:file->getFileDuration()];
    self.recordTypeLabel.text = [self translateMonitorType:file->getFileMotion()];
    self.videoStaticIcon.hidden = file->getFileType() == ICH_FILE_TYPE_VIDEO ? NO : YES;
    BOOL hidden = !file->getFileFavorite();
    SHLogDebug(SHLogTagAPP, @"hidden: %d", hidden);
    self.favoriteIcon.hidden = hidden;
}

- (void)setSelectedConfirmIconHidden:(BOOL)value
{
    [self.selectedComfirmIcon setHidden:value];
}

- (NSString *)translateMonitorType:(int)type {
    NSString *str = nil;
    
    switch (type) {
        case ICH_FILE_MONITOR_TYPE_ALL:
            break;
        case ICH_FILE_MONITOR_TYPE_AUDIO:
            break;
        case ICH_FILE_MONITOR_TYPE_MANUALLY:
            str = NSLocalizedString(@"kMonitorTypeManually", nil);
            break;
        case ICH_FILE_MONITOR_TYPE_PIR:
            str = NSLocalizedString(@"kMonitorTypePir", nil);
            break;
        case ICH_FILE_MONITOR_TYPE_RING:
            str = NSLocalizedString(@"kMonitorTypeRing", nil);
            break;
        case ICH_FILE_MONITOR_TYPE_UNKNOWN:
            break;
            
        default:
            break;
    }
    
    return str;
}

- (NSString *)translateDate:(string)date {
    NSMutableString *dateStr = [NSMutableString string];
    
    NSString *dateString = [NSString stringWithFormat:@"%s", date.c_str()];
    
    if (dateString.length == 15) {
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(0, 4)]];
        [dateStr appendString:@"-"];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(4, 2)]];
        [dateStr appendString:@"-"];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(6, 2)]];
        [dateStr appendString:@" "];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(9, 2)]];
        [dateStr appendString:@":"];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(11, 2)]];
        [dateStr appendString:@":"];
        [dateStr appendString:[dateString substringWithRange:NSMakeRange(13, 2)]];
        
        return dateStr.copy;
    } else {
        return dateString;
    }
}

- (NSString *)translateSize:(unsigned long long)sizeInKB
{
    NSString *humanDownloadFileSize = nil;
    double temp = (double)sizeInKB/1024; // MB
    if (temp > 1024) {
        temp /= 1024;
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fGB", temp];
    } else {
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fMB", temp];
    }
    return humanDownloadFileSize;
}

@end
