//
//  DIYCamPreview.m
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYAVPreview.h"

@implementation DIYAVPreview

#pragma mark - Init

- (void)_init
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [self orientationDidChange];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithSession:(AVCaptureSession *)session
{
    self = [super initWithSession:session];
    if (self) {
        [self _init];
    }
    return self;
}

#pragma mark - Public methods

- (void)reset
{
    [self orientationDidChange];    // Force orientation check
}

- (void)setForceOrientation:(BOOL)forceOrientation withDefaultOrientation:(AVCaptureVideoOrientation)defaultOrientation
{
    self.shouldForceOrientation = forceOrientation;
    self.defaultOrientation     = defaultOrientation;
    [self reset];
}

#pragma mark - Private methods
/*
 NOTE: [AVCaptureVideoPreviewLayer isOrientationSupported] is deprecated in favor of
        [AVCaptureVideoPreviewLayer connection].supportsVideoOrientation,
        but [AVCaptureVideoPreviewLayer connection] is only available in iOS 6.
        
        Same for [AVCaptureVideoPreviewLayer orientation] / [AVCaptureVideoPreviewLayer connection].videoOrientation
 */
- (void)orientationDidChange
{
    AVCaptureVideoOrientation newOrientation = self.defaultOrientation;

    if (!self.shouldForceOrientation && self.orientationSupported) {
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        
        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait:
                newOrientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            case UIDeviceOrientationLandscapeLeft:
                newOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                newOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            default:
                return;
                break;
        }
    }
    
    if (self.shouldForceOrientation || self.orientationSupported) {
        CGSize newSize = [self sizeForOrientation:[self isOrientationLandscape:newOrientation]];
        self.orientation    = newOrientation;
        self.frame          = CGRectMake(0, 0, newSize.width, newSize.height);
    }
}

- (BOOL)isOrientationLandscape:(AVCaptureVideoOrientation)videoOrientation
{
    BOOL isLandscape;
    
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
            isLandscape = false;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            isLandscape = false;
            break;
        case UIDeviceOrientationLandscapeLeft:
            isLandscape = true;
            break;
        case UIDeviceOrientationLandscapeRight:
            isLandscape = true;
            break;
        default:
            return false;
            break;
    }
    
    return isLandscape;
}

- (CGSize)sizeForOrientation:(BOOL)landscape
{
    CGFloat x = self.frame.size.width;
    CGFloat y = self.frame.size.height;
    
    if (landscape) {
        return (x > y) ? CGSizeMake(x, y) : CGSizeMake(y, x);
    }
    
    return (x <= y) ? CGSizeMake(x, y) : CGSizeMake(y, x);
}

#pragma mark - Dealloc

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
