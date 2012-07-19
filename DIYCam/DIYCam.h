//
//  DIYCam.h
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "DIYCamDefaults.h"
#import "DIYCamPreview.h"
#import "DIYCamUtilities.h"
#import "DIYCamFileOperation.h"
#import "DIYCamLibraryImageOperation.h"
#import "DIYCamLibraryVideoOperation.h"

//

typedef enum {
    DIYCamModePhoto,
    DIYCamModeVideo
} DIYCamMode;

@class DIYCam;

@protocol DIYCamDelegate <NSObject>
@required
- (void)camReady:(DIYCam *)cam;
- (void)camDidFail:(DIYCam *)cam withError:(NSError *)error;

- (void)camModeWillChange:(DIYCam *)cam mode:(DIYCamMode)mode;
- (void)camModeDidChange:(DIYCam *)cam mode:(DIYCamMode)mode;

- (void)camCaptureStarted:(DIYCam *)cam;
- (void)camCaptureStopped:(DIYCam *)cam;
- (void)camCaptureProcessing:(DIYCam *)cam;
- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset;
@end

//

@interface DIYCam : UIView <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, assign) id<DIYCamDelegate> delegate;
@property (nonatomic, assign) DIYCamMode captureMode;
@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, assign) BOOL isRecording;

- (void)capturePhoto;
- (void)captureVideoStart;
- (void)captureVideoStop;

@end