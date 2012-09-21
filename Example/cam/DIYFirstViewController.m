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
    self.cam.captureMode    = DIYCamModePhoto;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self releaseObjects];
    self.view = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return true;
}

#pragma mark - IBActions

- (IBAction)capturePhoto:(id)sender
{
    if (self.cam.captureMode == DIYCamModePhoto) {
        [self.cam capturePhoto];
    }
    else {
        if (self.cam.isRecording) {
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
            self.cam.captureMode = DIYCamModePhoto;
            break;
        case 1:
            self.cam.captureMode = DIYCamModeVideo;
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

#pragma mark - Dealloc

- (void)releaseObjects
{    
    _cam = nil;
    _selector = nil;
    _capture = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self releaseObjects];
}

- (void)dealloc
{
    [self releaseObjects];
}

@end
