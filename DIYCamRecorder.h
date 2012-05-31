//
//  DIYCamRecorder.h
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "DIYCamDefaults.h"
#import "DIYCamUtilities.h"

//

@class DIYCamRecorder;
@protocol DIYCamRecorderDelegate <NSObject>
@required
- (void)recorderRecordingDidBegin:(DIYCamRecorder *)recorder;
- (void)recorder:(DIYCamRecorder *)recorder recordingDidFinishToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error;
@end

//

@interface DIYCamRecorder : NSObject
{

}

@property (nonatomic,retain) AVCaptureSession *session;
@property (nonatomic,retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic,copy) NSURL *outputFileURL;
@property (nonatomic,readonly) BOOL recordsVideo;
@property (nonatomic,readonly) BOOL recordsAudio;
@property (nonatomic,readonly,getter=isRecording) BOOL recording;
@property (nonatomic,assign) id <NSObject,DIYCamRecorderDelegate> delegate;

- (id)initWithSession:(AVCaptureSession *)session outputFileURL:(NSURL *)outputFileURL;
- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation;
- (void)stopRecording;

@end