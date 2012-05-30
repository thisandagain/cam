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
@synthesize preview;
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Setup

- (void)setup
{
    // Camera
    cam = [[DIYCam alloc] init];
    [[self cam] setDelegate:self];
    
    // Preview
    AVCaptureVideoPreviewLayer *pl = [AVCaptureVideoPreviewLayer layerWithSession:[[self cam] session]];
    pl.frame = self.view.frame;
    [self.view.layer insertSublayer:pl below:[[self.view.layer sublayers] objectAtIndex:0]];
    
    // Gravity
    CGRect bounds   = self.view.layer.bounds;
    pl.videoGravity = AVLayerVideoGravityResizeAspectFill;
    pl.bounds       = bounds;
    pl.position     = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
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

- (void)cam:(DIYCam *)cam didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}

- (void)camCaptureStarted:(DIYCam *)cam
{
    
}

- (void)camCaptureStopped:(DIYCam *)cam
{
    
}

- (void)camCaptureProcessing:(DIYCam *)cam
{
    
}

- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset
{
    NSLog(@"Asset: %@", asset);
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [cam release]; cam = nil;
    
    [preview release]; preview = nil;
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
