//
//  ZJGridCell.m
//  ZJPhotoBrowserTest
//
//  Created by ZJ on 2018/5/29.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "ZJGridCell.h"
#import "Extensions/UIImage+ZJPhotoBrowser.h"

@interface ZJGridCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *videoIndicator;
@property (nonatomic, strong) UIButton *selectedButton;

@end

@implementation ZJGridCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        // ImageView
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.autoresizesSubviews = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_imageView];
        
        // Video icon
        _videoIndicator = [UIImageView new];
        _videoIndicator.hidden = NO;
        UIImage *videoIndicatorImage = [UIImage imageForResourcePath:@"ZJPhotoBrowser.bundle/icons/video item-btn" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        _videoIndicator.frame = CGRectMake((self.bounds.size.width - videoIndicatorImage.size.width) * 0.5, (self.bounds.size.height - videoIndicatorImage.size.height) * 0.5, videoIndicatorImage.size.width, videoIndicatorImage.size.height);
//        _videoIndicator.center = self.center;
        _videoIndicator.image = videoIndicatorImage;
        _videoIndicator.autoresizesSubviews = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:_videoIndicator];
        
        // Selection button
        _selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectedButton.contentMode = UIViewContentModeRight;
        _selectedButton.adjustsImageWhenHighlighted = NO;
        [_selectedButton setImage:[UIImage imageForResourcePath:@"ZJPhotoBrowser.bundle/images/ImageSelectedSmallOff" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateNormal];
        [_selectedButton setImage:[UIImage imageForResourcePath:@"ZJPhotoBrowser.bundle/images/ImageSelectedSmallOn" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateSelected];
        [_selectedButton addTarget:self action:@selector(selectionButtonPressed) forControlEvents:UIControlEventTouchDown];
        _selectedButton.hidden = YES;
        _selectedButton.frame = CGRectMake(0, 0, 44, 44);
        [self addSubview:_selectedButton];
        
        // Loading
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                     name:kZJPhotoLoadingDidEndNotification
                                                   object:nil];
    }
    return self;
}

// MARK: - Image Handling
- (void)setPhoto:(id<ZJPhotoProtocol>)photo {
    _photo = photo;
    
    if ([photo respondsToSelector:@selector(isVideo)]) {
        _videoIndicator.hidden = !photo.isVideo;
    } else {
        _videoIndicator.hidden = YES;
    }
    
//    _imageView.backgroundColor = [UIColor orangeColor];
}

- (void)displayImage {
    _imageView.image = [_photo underlyingImage];
}

// MARK: - Selection
- (void)setSelectionMode:(BOOL)selectionMode {
    _selectionMode = selectionMode;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    _selectedButton.selected = isSelected;
}

- (void)selectionButtonPressed {
    _selectedButton.selected = !_selectedButton.selected;
}

- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <ZJPhotoProtocol> photo = [notification object];
    if (photo == _photo) {
        if ([photo underlyingImage]) {
            // Successful load
            [self displayImage];
        } else {
            // Failed to load
//            [self showImageFailure];
        }
//        [self hideLoadingIndicator];
    }
}

@end
