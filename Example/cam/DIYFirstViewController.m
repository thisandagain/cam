//
//  DIYFirstViewController.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYFirstViewController.h"

@implementation DIYFirstViewController

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Camera", @"Camera");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.selector addTarget:self action:@selector(selectorChanged:) forControlEvents:UIControlEventValueChanged];
	
    // Setup cam
    self.cam.delegate       = self;
    [self.cam setCamMode:DIYCamModePhoto];
    
    // Tap to focus indicator
    // -------------------------------------
    UIImage *defaultImage   = [UIImage imageNamed:@"focus_indicator@2x.png"];
    _focusImageView         = [[UIImageView alloc] initWithImage:defaultImage];
    self.focusImageView.frame   = CGRectMake(0, 0, defaultImage.size.width, defaultImage.size.height);
    self.focusImageView.hidden = YES;
    [self.view addSubview:self.focusImageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAtTap:)];
    tap.delegate = self;
    tap.cancelsTouchesInView = false;
    [self.cam addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view bringSubviewToFront:self.focusImageView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.view = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return true;
}

#pragma mark - IBActions

- (IBAction)capturePhoto:(id)sender
{
    if ([self.cam getCamMode] == DIYCamModePhoto) {
        [self.cam capturePhoto];
    }
    else {
        if ([self.cam getRecordingStatus]) {
            [self.cam captureVideoStop];
        }
        else {
            [self.cam captureVideoStart];
        }
    }
}

- (IBAction)selectorChanged:(id)sender
{
    switch (self.selector.selectedSegmentIndex) {
        case 0:
            [self.cam setCamMode:DIYCamModePhoto];
            break;
        case 1:
            [self.cam setCamMode:DIYCamModeVideo];
            break;
        default:
            [NSException raise:@"SelectorOutOfBounds" format:@"Selector changed to %d, which is out of bounds", self.selector.selectedSegmentIndex];
            break;
    }
}

#pragma mark - DIYCamDelegate

- (void)camReady:(DIYCam *)cam
{
    NSLog(@"Ready");
}

- (void)camDidFail:(DIYCam *)cam withError:(NSError *)error
{
    NSLog(@"Fail");
}

- (void)camModeWillChange:(DIYCam *)cam mode:(DIYCamMode)mode
{
    NSLog(@"Mode will change");
}

- (void)camModeDidChange:(DIYCam *)cam mode:(DIYCamMode)mode
{
    NSLog(@"Mode did change");
}

- (void)camCaptureStarted:(DIYCam *)cam
{
    NSLog(@"Capture started");
}

- (void)camCaptureStopped:(DIYCam *)cam
{
    NSLog(@"Capture stopped");
}

- (void)camCaptureProcessing:(DIYCam *)cam
{
    NSLog(@"Capture processing");
}

- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset
{
    NSLog(@"Capture complete. Asset: %@", asset);
}

#pragma mark - UIGesture

- (void)focusAtTap:(UIGestureRecognizer *)gestureRecognizer
{
    self.focusImageView.center = [gestureRecognizer locationInView:self.cam];
    [self animateFocusImage:0];
}

#pragma mark - Focus reticle

- (void)animateFocusImage:(int)stage
{
    switch (stage) {
        case 0: {
            self.focusImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
            self.focusImageView.alpha = 0.0;
            self.focusImageView.hidden = NO;
            [self animateFocusImage:1];
        }
            break;
            
        case 1: {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.focusImageView.transform = CGAffineTransformIdentity;
                                 self.focusImageView.alpha = 1.0;
                             }
                             completion:^(BOOL finished){
                                 [self animateFocusImage:2];
                             }];
        }
            break;
            
        case 2: {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.focusImageView.alpha = 0.5;
                             }
                             completion:^(BOOL finished){
                                 [self animateFocusImage:3];
                             }];
        }
            break;
            
        case 3: {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.focusImageView.alpha = 1.0;
                             }
                             completion:^(BOOL finished){
                                 [self animateFocusImage:4];
                             }];
        }
            break;
            
        case 4: {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.focusImageView.alpha = 0.0;
                             }
                             completion:^(BOOL finished){
                                 self.focusImageView.hidden = YES;
                             }];
        }
            break;
    }
}

#pragma mark - UIGestureRecognizer Delegate

// We're running two UIGestureRecognizers attached to cam at once. One has this
// ViewController as its target to handle the UI display side. The other is internal
// to cam and actually adjusts the focus. Implementing this delegate method allows
// both gesture regonizers to fire with the same tap.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return true;
}

#pragma mark - Dealloc

- (void)dealloc
{
    _cam = nil;
    _selector = nil;
    _capture = nil;
}

@end
