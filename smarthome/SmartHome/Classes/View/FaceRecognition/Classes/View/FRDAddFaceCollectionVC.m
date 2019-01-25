// FRDAddFaceCollectionVC.m

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
 
 // Created by zj on 2019/1/9 7:39 PM.
    

#import "FRDAddFaceCollectionVC.h"
#import "FRDFaceData.h"
#import "FaceCollectionViewCell.h"
#import "FRDCommonHeader.h"
#import "SVProgressHUD.h"
#import "SHNetworkManager+SHFaceHandle.h"
#import "FaceCollectionReusableView.h"

static CGFloat kFaceCellWidth = 110;
static CGFloat kFaceCellHeight = 140;
static CGFloat kCellLeftMargin = 20;

@interface FRDAddFaceCollectionVC () <FaceCollectionViewCellDelete>

@property (nonatomic, strong) NSMutableArray<FRDFaceData *> *facesMarray;
@property (nonatomic, strong) UIImage *currentFaceImage;
@property (nonatomic, copy) NSString *userName;

@end

@implementation FRDAddFaceCollectionVC

static NSString * const reuseIdentifier = @"FaceCollectionViewCellID";
static NSString * const reuseIdentifierHeader = @"FaceCollectionViewCellHeaderID";

+ (instancetype)addFaceCollectionVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kFaceRecognitionStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"FRDAddFaceCollectionVCSBID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[FaceCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    [self setupGUI];
    [self fetchedFacesImage];
    [self setupLocalizedString];
}

- (void)setupLocalizedString {
    self.title = NSLocalizedString(@"kAddFaces", nil);
}

- (void)setupGUI {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    layout.itemSize = CGSizeMake(kFaceCellWidth, kFaceCellHeight);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
//    layout.sectionInset = UIEdgeInsetsMake(2, 10, 2, 10);
    
    self.collectionView.collectionViewLayout = layout;
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.facesMarray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FaceCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    cell.faceData = self.facesMarray[indexPath.row];
    cell.delegate = self;
    
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat margin = self.facesMarray.count > 1 ? kCellLeftMargin : (CGRectGetWidth(self.view.bounds) - kFaceCellWidth) * 0.5;
    
    return UIEdgeInsetsMake(2, margin, 2, margin);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    FaceCollectionReusableView *reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifierHeader forIndexPath:indexPath];
    
    reusableView.originalImage = self.originalImage;
    reusableView.resultDescription = [self recognitionResultDes];

    return reusableView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGFloat margin = 10;
    CGFloat labelH = [SHTool stringSizeWithString:[self recognitionResultDes] font:[UIFont systemFontOfSize:17.0]].height;
    CGSize rect = CGSizeMake(CGRectGetWidth(collectionView.bounds), self.originalImage.size.height + 2 * margin + labelH);
    return rect;
}

- (NSString *)recognitionResultDes {
    NSString *str = nil;
    if (self.facesRectArray.count <= 0) {
        str = NSLocalizedString(@"kNotRecognizeFaceFromPicture", nil);
    } else {
        str = [NSString stringWithFormat:NSLocalizedString(@"kRecognitionFaceFromPicture", nil), (unsigned long)self.facesRectArray.count];
    }
    
    SHLogInfo(SHLogTagAPP, @"Face recognition result: %@", str);
    
    return str;
}

- (void)opertionClickWithFaceCollectionViewCell:(FaceCollectionViewCell *)cell {
    self.currentFaceImage = cell.faceData.faceImage;
    
    [self showAddFacesAlertView];
}

#pragma mark - Init
- (NSMutableArray<FRDFaceData *> *)facesMarray {
    if (_facesMarray == nil) {
        _facesMarray = [[NSMutableArray alloc] init];
    }
    
    return _facesMarray;
}

#pragma mark - Fetched Faces image
- (void)fetchedFacesImage {
    WEAK_SELF(self);
    
    [self.facesMarray removeAllObjects];
    [self.facesRectArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        STRONG_SELF(self);
        
        CGRect rect = CGRectFromString(obj);
        CGFloat margin = 10;
        rect = CGRectMake(CGRectGetMinX(rect) - margin, CGRectGetMinY(rect) - margin * 2, CGRectGetWidth(rect) + margin * 2, CGRectGetHeight(rect) + margin * 2);
        UIImage *faceImgae = [self imageFromImage:self.originalImage inRect:rect];
        
        if (faceImgae != nil) {
            FRDFaceData *faceData = [[FRDFaceData alloc] init];
            
            faceData.faceImage = faceImgae;
            faceData.title = NSLocalizedString(@"kAdd", nil);
            
            [self.facesMarray addObject:faceData];
        }
    }];
}

- (UIImage*)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    rect = CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect));
    
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}

#pragma mark - Add Faces Handler
- (void)showAddFacesAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kSetupFaceName", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *nameTextField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        
        nameTextField = textField;
    }];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kUploadFacePicture", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = nameTextField.text;
        
        STRONG_SELF(self);
        if (name == nil || [name isEqualToString:@""]) {
            [self inputEmptyAlert];
        } else {
            if ([self hasFaceInfoWithName:name]) {
                [self alreadyExistFaceInfoAlert:name];
            } else {
                [self uploadHandlerWithName:name];
            }
        }
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)uploadHandlerWithName:(NSString *)name {
    self.userName = name;
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    NSData *data = UIImageJPEGRepresentation(self.currentFaceImage, 1.0);
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] uploadFacePicture:data name:name finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        [weakself resultHandler:error];
    }];
}

- (void)resultHandler:(ZJRequestError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        
        if (error != nil) {
            NSLog(@"error: %@", error);
            
            [SVProgressHUD showErrorWithStatus:error.error];
            [SVProgressHUD dismissWithDelay:2.0];
        } else {
            //            [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"kAddFacePictureSuccess", nil), self.userName]];
            [SVProgressHUD dismissWithDelay:2.0];
            
            if (self.facesMarray.count == 1) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }

            [self updateFaceData];
            [self.collectionView reloadData];
        }
    });
}

- (void)updateFaceData {
    [self.facesMarray enumerateObjectsUsingBlock:^(FRDFaceData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.currentFaceImage == obj.faceImage) {
            obj.alreadyAdd = YES;
            
            obj.title = NSLocalizedString(@"kAddSuccess", nil);
            
            *stop = YES;
        }
    }];
}

- (void)alreadyExistFaceInfoAlert:(NSString *)name {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:[NSString stringWithFormat:NSLocalizedString(@"kFaceAlreadyExist", nil), name] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddFacesAlertView];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (BOOL)hasFaceInfoWithName:(NSString *)name {
    __block BOOL has = false;
    NSArray *localFaces = [[NSUserDefaults standardUserDefaults] objectForKey:kLocalFacesInfo];
    
    if (localFaces && localFaces.count > 0) {
        [localFaces enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj[@"name"] isEqualToString:name]) {
                has = true;
                *stop = true;
            }
        }];
    }
    
    return has;
}

- (void)inputEmptyAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"kFaceNameInvalid", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAddFacesAlertView];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
