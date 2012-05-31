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
#import "UIImage+Resize.h"
#import "DIYCamUtilities.h"

//

@class DIYCam;
@protocol DIYCamDelegate <NSObject>
@required
- (void)camReady:(DIYCam *)cam;
- (void)camDidFail:(DIYCam *)cam withError:(NSError *)error;
- (void)camCaptureStarted:(DIYCam *)cam;
- (void)camCaptureStopped:(DIYCam *)cam;
- (void)camCaptureProcessing:(DIYCam *)cam;
- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset;
@end

//

@interface DIYCam : NSObject <AVCaptureFileOutputRecordingDelegate>
{
    BOOL isRecording;
}

@property (nonatomic, assign) id <DIYCamDelegate> delegate;
@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic, retain) AVCaptureDeviceInput *audioInput;

@property (nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, retain) ALAssetsLibrary *library;

#pragma mark - Setup

- (void)setup;

#pragma mark - Photo

- (void)startPhotoCapture;

#pragma mark - Video

- (void)startVideoCapture;
- (void)stopVideoCapture;

#pragma mark - Utilities

- (bool)isRecording;
- (NSString *)createAssetFilePath:(NSString *)extension;

@end