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
#import <MobileCoreServices/UTCoreTypes.h>

#import "DIYCamDefaults.h"
#import "DIYCamUtilities.h"

#import "UIImage+Resize.h"
#import "UIImage+Save.h"

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
    @private AVCaptureDeviceInput *videoInput;
    @private AVCaptureDeviceInput *audioInput;
    
    @private AVCaptureStillImageOutput *stillImageOutput;
    @private AVCaptureMovieFileOutput *movieFileOutput;
    @private AVAssetImageGenerator *thumbnailGenerator;
    @private ALAssetsLibrary *library;
}

@property (nonatomic, assign) id <DIYCamDelegate> delegate;
@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, assign) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, assign) BOOL isRecording;

#pragma mark - Setup

- (void)setup;

#pragma mark - Photo

- (void)startPhotoCapture;

#pragma mark - Video

- (void)startVideoCapture;
- (void)stopVideoCapture;

#pragma mark - Utilities

- (NSString *)createAssetFilePath:(NSString *)extension;

@end