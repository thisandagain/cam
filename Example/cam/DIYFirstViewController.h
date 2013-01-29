//
//  DIYFirstViewController.h
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DIYCam.h"

@interface DIYFirstViewController : UIViewController <DIYCamDelegate, UIGestureRecognizerDelegate>

@property IBOutlet DIYCam *cam;
@property IBOutlet UISegmentedControl *selector;
@property IBOutlet UIButton *capture;
@property UIImageView *focusImageView;

- (IBAction)capturePhoto:(id)sender;

@end