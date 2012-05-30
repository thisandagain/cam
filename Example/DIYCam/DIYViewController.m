//
//  DIYViewController.m
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYViewController.h"

@implementation DIYViewController

@synthesize cam;
@synthesize display;
@synthesize capturePhoto;
@synthesize captureVideo;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark - Setup

- (void)setup
{
    // Camera
    cam = [[DIYCam alloc] init];
    [[self cam] setDelegate:self];
    
    // Preview
    cam.preview.frame       = display.frame;
    [display.layer addSublayer:cam.preview];
    
    CGRect bounds           = display.layer.bounds;
    cam.preview.bounds      = bounds;
    cam.preview.position    = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
}

#pragma mark - UI events

- (IBAction)triggerPhotoCapture:(id)sender
{
    [cam startPhotoCapture];
}

- (IBAction)toggleVideoCapture:(id)sender
{
    if (![cam isRecording]) 
    {
        captureVideo.titleLabel.text = @"Recording...";
        [cam startVideoCapture];
    } else {
        captureVideo.titleLabel.text = @"Start Recording";
        [cam stopVideoCapture];
    }
}

#pragma mark - Delegate events

- (void)camReady:(DIYCam *)cam
{
    NSLog(@"Ready");
}

- (void)camDidFail:(DIYCam *)cam withError:(NSError *)error
{
    NSLog(@"Error: %@", error);
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
    NSLog(@"Capture Processing...");
}

- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset
{
    NSLog(@"Asset: %@", asset);
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [cam release]; cam = nil;
    
    [display release]; display = nil;
    [capturePhoto release]; capturePhoto = nil;
    [captureVideo release]; captureVideo = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self releaseObjects];
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end
