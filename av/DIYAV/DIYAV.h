//
//  DIYAV.h
//  DIYAV
//
//  Created by Jonathan Beilin on 1/22/13.
//  Copyright (c) 2013 DIY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DIYAVDefaults.h"

@class DIYAVPreview;
@class DIYAV;

typedef enum {
    DIYAVModePhoto,
    DIYAVModeVideo
} DIYAVMode;

// Settings
NSString *const DIYAVSettingFlash;
NSString *const DIYAVSettingOrientationForce;
NSString *const DIYAVSettingOrientationDefault;
NSString *const DIYAVSettingCameraPosition;
NSString *const DIYAVSettingCameraHighISO;
NSString *const DIYAVSettingPhotoPreset;
NSString *const DIYAVSettingPhotoGravity;
NSString *const DIYAVSettingVideoPreset;
NSString *const DIYAVSettingVideoGravity;
NSString *const DIYAVSettingVideoMaxDuration;
NSString *const DIYAVSettingVideoFPS;
NSString *const DIYAVSettingSaveLibrary;

//

@protocol DIYAVDelegate <NSObject>
@required
- (void)AVAttachPreviewLayer:(CALayer *)layer;

- (void)AVDidFail:(DIYAV *)av withError:(NSError *)error;

- (void)AVModeWillChange:(DIYAV *)av mode:(DIYAVMode)mode;
- (void)AVModeDidChange:(DIYAV *)av mode:(DIYAVMode)mode;

- (void)AVCaptureStarted:(DIYAV *)av;
- (void)AVCaptureStopped:(DIYAV *)av;
- (void)AVcaptureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL shouldSaveToLibrary:(BOOL)shouldSaveToLibrary fromConnections:(NSArray *)connections error:(NSError *)error;
- (void)AVCaptureOutputStill:(CMSampleBufferRef)imageDataSampleBuffer shouldSaveToLibrary:(BOOL)shouldSaveToLibrary withError:(NSError *)error;
@end

//

@interface DIYAV : NSObject <AVCaptureFileOutputRecordingDelegate>

@property (weak)        id<DIYAVDelegate>   delegate;
@property (nonatomic)   DIYAVMode           captureMode;
@property               BOOL                isRecording;

- (id)initWithOptions:(NSDictionary *)options;

- (void)startSession;
- (void)stopSession;
- (void)focusAtPoint:(CGPoint)point inFrame:(CGRect)frame;
- (void)capturePhoto;
- (void)captureVideoStart;
- (void)captureVideoStop;

@end
