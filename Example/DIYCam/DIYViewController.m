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
@synthesize thumbnail;

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
    // Init camera
    cam = [[DIYCam alloc] init];
    [[self cam] setDelegate:self];
    [[self cam] setup];
    
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
        [captureVideo setTitle:@"Recording..." forState:UIControlStateNormal];
        [cam startVideoCapture];
    } else {
        [captureVideo setTitle:@"Start Recording" forState:UIControlStateNormal];
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
    if ([[asset objectForKey:@"type"] isEqualToString:@"video"])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            UIImage *image = [UIImage imageWithContentsOfFile:[asset objectForKey:@"thumbnail"]];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                thumbnail.image = image;
            });
            
        });
    }
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [cam release]; cam = nil;
    
    [display release]; display = nil;
    [capturePhoto release]; capturePhoto = nil;
    [captureVideo release]; captureVideo = nil;
    [thumbnail release]; thumbnail = nil;
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
