//
//  DIYViewController.h
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DIYCam.h"

@interface DIYViewController : UIViewController <DIYCamDelegate>
{
    
}

@property (nonatomic, retain) DIYCam *cam;

@property (nonatomic, retain) IBOutlet UIView *display;
@property (nonatomic, retain) IBOutlet UIButton *capturePhoto;
@property (nonatomic, retain) IBOutlet UIButton *captureVideo;

- (IBAction)triggerPhotoCapture:(id)sender;
- (IBAction)toggleVideoCapture:(id)sender;

@end