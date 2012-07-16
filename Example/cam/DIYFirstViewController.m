//
//  DIYFirstViewController.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYFirstViewController.h"

@implementation DIYFirstViewController

@synthesize cam = _cam;
@synthesize selector = _selector;
@synthesize capture = _capture;

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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - IBActions

- (IBAction)capturePhoto:(id)sender
{
    [self.cam capturePhoto:^(NSDictionary *asset) {
        NSLog(@"Asset: %@", asset);
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];
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

#pragma mark - Dealloc

- (void)releaseObjects
{    
    [_cam release]; _cam = nil;
    [_selector release]; _selector = nil;
    [_capture release]; _capture = nil;
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
