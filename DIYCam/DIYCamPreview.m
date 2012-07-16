//
//  DIYCamPreview.m
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamPreview.h"

@implementation DIYCamPreview

#pragma mark - Init

- (void)_init
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
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

#pragma mark - Private methods

- (void)orientationDidChange
{
    if (!DEVICE_ORIENTATION_FORCE && self.orientationSupported) {
        
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        AVCaptureVideoOrientation newOrientation;
        BOOL isLandscape;
        
        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait:
                newOrientation = AVCaptureVideoOrientationPortrait;
                isLandscape = false;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                isLandscape = false;
                break;
            case UIDeviceOrientationLandscapeLeft:
                newOrientation = AVCaptureVideoOrientationLandscapeRight;
                isLandscape = true;
                break;
            case UIDeviceOrientationLandscapeRight:
                newOrientation = AVCaptureVideoOrientationLandscapeLeft;
                isLandscape = true;
                break;
            default:
                return;
                break;
        }
        
        CGSize newSize = [self sizeForOrientation:isLandscape];
        self.orientation    = newOrientation;
        self.frame          = CGRectMake(0, 0, newSize.width, newSize.height);
    }
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

- (void)releaseObjects
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end
