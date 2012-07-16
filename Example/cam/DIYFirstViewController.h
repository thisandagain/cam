//
//  DIYFirstViewController.h
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DIYCam.h"

@interface DIYFirstViewController : UIViewController <DIYCamDelegate>

@property (nonatomic, retain) IBOutlet DIYCam *cam;
@property (nonatomic, retain) IBOutlet UISegmentedControl *selector;
@property (nonatomic, retain) IBOutlet UIButton *capture;

- (IBAction)capturePhoto:(id)sender;

@end