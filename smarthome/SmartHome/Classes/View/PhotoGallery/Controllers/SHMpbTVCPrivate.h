//
//  SHMpbTVCPrivate.h
//  SmartHome
//
//  Created by ZJ on 2017/5/3.
//  Copyright © 2017年 ZJ. All rights reserved.
//
enum SHMpbState{
    SHMpbStateNor = 0,
    SHMpbStateEdit,
};

#import "SHMpbTVC.h"
#import "SHFileTable.h"
#import "CustomIOS7AlertView.h"
#import "SHDatabase.h"

@interface SHMpbTVC ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showFilterButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showDownloadButton;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *calendarButton;
@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (weak, nonatomic) IBOutlet UIView *firstView;
@property (weak, nonatomic) IBOutlet UIButton *secondButton;
@property (weak, nonatomic) IBOutlet UIView *secondView;
@property (weak, nonatomic) IBOutlet UIButton *thirdButton;
@property (weak, nonatomic) IBOutlet UIView *thirdView;
@property (weak, nonatomic) IBOutlet UIButton *fourthButton;
@property (weak, nonatomic) IBOutlet UIView *fourthView;
@property (weak, nonatomic) IBOutlet UIButton *fifthButton;
@property (weak, nonatomic) IBOutlet UIView *fifthView;
@property (weak, nonatomic) IBOutlet UIButton *sixthButton;
@property (weak, nonatomic) IBOutlet UIView *sixthView;
@property (weak, nonatomic) IBOutlet UIButton *seventhButton;
@property (weak, nonatomic) IBOutlet UIView *seventhView;
@property (weak, nonatomic) IBOutlet UIButton *eighthButton;
@property (weak, nonatomic) IBOutlet UIView *eighthView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *unfavoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *selectedButton;
@property (weak, nonatomic) IBOutlet UIButton *selectedNumber;

@property (weak, nonatomic) IBOutlet UIView *favoriteView;
@property (weak, nonatomic) IBOutlet UIView *unfavoriteView;

@property (nonatomic) SHCameraObject *shCamObj;
@property (nonatomic) SHControlCenter *ctrl;

@property (nonatomic) SHMpbState curMpbState;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic) MBProgressHUD *progressHUDFilter;
@property (nonatomic) SHFileTable *curFileTable;
@property (nonatomic) NSString *curDate;
@property(nonatomic) SHTableViewSelectedCellTable *selCellsTable;
@property (nonatomic, strong) NSCache *mpbCache;

@property(nonatomic) UIImage *videoPlaybackThumb;
@property(nonatomic) NSUInteger videoPlaybackIndex;

@property(nonatomic) UIActivityViewController *activityViewController;
@property(nonatomic) UIPopoverController *popController;
@property(nonatomic) UIAlertController *actionSheet;
@property(nonatomic, getter = isRun) BOOL run;
@property(nonatomic) dispatch_semaphore_t mpbSemaphore;
@property(nonatomic) unsigned long long totalDownloadSize;
@property(nonatomic) BOOL cancelDownload;
@property(nonatomic) int observerNo;
@property(nonatomic) NSUInteger totalCount;
@property(nonatomic) NSUInteger totalDownloadFileNumber;
@property(nonatomic) NSUInteger downloadedFileNumber;
@property(nonatomic) NSUInteger downloadedPercent;
@property(nonatomic) NSInteger downloadFailedCount;
@property(nonatomic) dispatch_queue_t thumbnailQueue;
@property(nonatomic) dispatch_queue_t downloadQueue;
@property(nonatomic) dispatch_queue_t downloadPercentQueue;
@property(nonatomic) BOOL downloadFileProcessing;
@property (nonatomic, strong) CustomIOS7AlertView *filterView;
@property (nonatomic, strong) NSArray *filterArray;
@property (nonatomic, strong) NSMutableArray *selectedFilterCells;
@property (nonatomic, weak) UITableView *filterTableView;

@property (nonatomic) SHDatabase *db;
@property (nonatomic, strong) NSDate *remoteDateTime;

//@property (nonatomic) BOOL isDownloading;
//@property (nonatomic) BOOL readyGoToFileDownloadVC;
@property (nonatomic, strong) NSMutableArray *curSelectedCells;

@property (nonatomic, strong) dispatch_queue_t getThumbnailQueue;

@end
