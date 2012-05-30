//
//  DIYCam.h
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "DIYCamDefaults.h"
#import "DIYCamRecorder.h"
#import "DIYCamScaler.h"
#import "DIYCamUtilities.h"

//

@class DIYCam;
@protocol DIYCamDelegate <NSObject>
@optional
- (void)camReady:(DIYCam *)cam;
- (void)cam:(DIYCam *)cam didFailWithError:(NSError *)error;
- (void)camCaptureStarted:(DIYCam *)cam;
- (void)camCaptureStopped:(DIYCam *)cam;
- (void)camCaptureProcessing:(DIYCam *)cam;
- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset;
@end

//

@interface DIYCam : NSObject
{
    
}

@property (nonatomic, assign) id <DIYCamDelegate> delegate;
@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
@property (nonatomic, retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic, retain) AVCaptureDeviceInput *audioInput;
@property (nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) DIYCamRecorder *recorder;

#pragma mark - Photo

- (void)startPhotoCapture;

#pragma mark - Video

- (void)startVideoCapture;
- (void)stopVideoCapture;

#pragma mark - Utility

- (bool)isRecording;

@end