//
//  DIYAV.m
//  DIYAV
//
//  Created by Jonathan Beilin on 1/22/13.
//  Copyright (c) 2013 DIY. All rights reserved.
//

#import "DIYAV.h"

#import "DIYAVDefaults.h"
#import "DIYAVUtilities.h"
#import "DIYAVPreview.h"

#import "Underscore.h"

NSString *const DIYAVSettingFlash                  = @"DIYAVSettingFlash";
NSString *const DIYAVSettingOrientationForce       = @"DIYAVSettingOrientationForce";
NSString *const DIYAVSettingOrientationDefault     = @"DIYAVSettingOrientationDefault";
NSString *const DIYAVSettingCameraPosition         = @"DIYAVSettingCameraPosition";
NSString *const DIYAVSettingCameraHighISO          = @"DIYAVSettingCameraHighISO";
NSString *const DIYAVSettingPhotoPreset            = @"DIYAVSettingPhotoPreset";
NSString *const DIYAVSettingPhotoGravity           = @"DIYAVSettingPhotoGravity";
NSString *const DIYAVSettingVideoPreset            = @"DIYAVSettingVideoPreset";
NSString *const DIYAVSettingVideoGravity           = @"DIYAVSettingVideoGravity";
NSString *const DIYAVSettingVideoMaxDuration       = @"DIYAVSettingVideoMaxDuration";
NSString *const DIYAVSettingVideoFPS               = @"DIYAVSettingVideoFPS";
NSString *const DIYAVSettingSaveLibrary            = @"DIYAVSettingSaveLibrary";

@interface DIYAV ()

@property NSDictionary              *options;

@property DIYAVPreview              *preview;
@property AVCaptureSession          *session;
@property AVCaptureDeviceInput      *videoInput;
@property AVCaptureDeviceInput      *audioInput;
@property AVCaptureStillImageOutput *stillImageOutput;
@property AVCaptureMovieFileOutput  *movieFileOutput;

@end

@implementation DIYAV

#pragma mark - Init

- (void)_init
{
    // Options
    NSDictionary *defaultOptions;
    defaultOptions          = @{ DIYAVSettingFlash              : @false,
                                 DIYAVSettingOrientationForce   : @false,
                                 DIYAVSettingOrientationDefault : [NSNumber numberWithInt:AVCaptureVideoOrientationLandscapeRight],
                                 DIYAVSettingCameraPosition     : [NSNumber numberWithInt:AVCaptureDevicePositionBack],
                                 DIYAVSettingCameraHighISO      : @true,
                                 DIYAVSettingPhotoPreset        : AVCaptureSessionPresetPhoto,
                                 DIYAVSettingPhotoGravity       : AVLayerVideoGravityResizeAspectFill,
                                 DIYAVSettingVideoPreset        : AVCaptureSessionPreset1280x720,
                                 DIYAVSettingVideoGravity       : AVLayerVideoGravityResizeAspectFill,
                                 DIYAVSettingVideoMaxDuration   : @300,
                                 DIYAVSettingVideoFPS           : @30,
                                 DIYAVSettingSaveLibrary        : @true };
    
    _options                = Underscore.dict(_options)
                              .defaults(defaultOptions)
                              .unwrap;
    
    // AV setup
    _captureMode            = DIYAVModePhoto;
    _session                = [[AVCaptureSession alloc] init];
    
    _preview                = [[DIYAVPreview alloc] initWithSession:_session];
    _videoInput             = nil;
    _audioInput             = nil;
    _stillImageOutput       = [[AVCaptureStillImageOutput alloc] init];
    _movieFileOutput        = [[AVCaptureMovieFileOutput alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        _options = @{};
        [self _init];
    }

    return self;
}

- (id)initWithOptions:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        if (!options) {
            options = @{};
        }
        _options = options;
        [self _init];
    }
    
    return self;
}

#pragma mark - Public methods

- (void)startSession
{
    if (self.session != nil && !self.session.isRunning) {
        [self.session startRunning];
    }
}

- (void)stopSession
{
    if (self.session != nil && self.session.isRunning) {
        [self.session stopRunning];
    }
}

- (void)focusAtPoint:(CGPoint)point inFrame:(CGRect)frame
{
    if (self.videoInput.device.isFocusPointOfInterestSupported && [self.videoInput.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        CGPoint focusPoint = [DIYAVUtilities convertToPointOfInterestFromViewCoordinates:point withFrame:frame withPreview:self.preview withPorts:self.videoInput.ports];
        NSError *error;
        if ([self.videoInput.device lockForConfiguration:&error]) {
            self.videoInput.device.focusPointOfInterest = focusPoint;
            self.videoInput.device.focusMode = AVCaptureFocusModeAutoFocus;
            [self.videoInput.device unlockForConfiguration];
        }
        else {
            [self.delegate AVDidFail:self withError:error];
        }
    }
}

- (void)capturePhoto
{
    if (self.session != nil) {
        
        // Connection
        AVCaptureConnection *stillImageConnection = [DIYAVUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.stillImageOutput connections]];
        if ([self.options valueForKey:DIYAVSettingOrientationForce]) {
            stillImageConnection.videoOrientation = [[self.options valueForKey:DIYAVSettingOrientationDefault] integerValue];
        } else {
            stillImageConnection.videoOrientation = [[UIDevice currentDevice] orientation];
        }
        
        // Capture image async block
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            [self.delegate AVCaptureOutputStill:imageDataSampleBuffer shouldSaveToLibrary:[[self.options valueForKey:DIYAVSettingSaveLibrary] boolValue] withError:error];
        }];
    } else {
        [self.delegate AVDidFail:self withError:[NSError errorWithDomain:@"com.diy.av" code:500 userInfo:nil]];
    }
}

- (void)captureVideoStart
{
    if (self.session != nil) {
        [self setIsRecording:true];
        [self.delegate AVCaptureStarted:self];
        
        // Create URL to record to
        NSString *assetPath         = [DIYAVUtilities createAssetFilePath:@"mov"];
        NSURL *outputURL            = [[NSURL alloc] initFileURLWithPath:assetPath];
        NSFileManager *fileManager  = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:assetPath]) {
            NSError *error;
            if ([fileManager removeItemAtPath:assetPath error:&error] == NO) {
                [self.delegate AVDidFail:self withError:error];
            }
        }
        
        // Record in the correct orientation
        AVCaptureConnection *videoConnection = [DIYAVUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.movieFileOutput connections]];
        if ([videoConnection isVideoOrientationSupported] && ![[self.options valueForKey:DIYAVSettingOrientationForce] boolValue]) {
            [videoConnection setVideoOrientation:[DIYAVUtilities getAVCaptureOrientationFromDeviceOrientation]];
        } else {
            [videoConnection setVideoOrientation:[[self.options valueForKey:DIYAVSettingOrientationDefault] integerValue]];
        }
        
        // Start recording
        [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    }
}

- (void)captureVideoStop
{
    if (self.session != nil && self.isRecording)
    {
        [self setIsRecording:false];
        [self.delegate AVCaptureStopped:self];
        
        [self.movieFileOutput stopRecording];
    }
}

#pragma mark - Override

- (void)setCaptureMode:(DIYAVMode)captureMode
{
    // Super
    self->_captureMode = captureMode;
    
    //
    
    [self.delegate AVModeWillChange:self mode:captureMode];
    
    switch (captureMode) {
            // Photo mode
            // -------------------------------------
        case DIYAVModePhoto:
            if ([DIYAVUtilities isPhotoCameraAvailable]) {
                [self establishPhotoMode];
            } else {
                [self.delegate AVDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:100 userInfo:nil]];
            }
            break;
            
            // Video mode
            // -------------------------------------
        case DIYAVModeVideo:
            if ([DIYAVUtilities isVideoCameraAvailable]) {
                [self establishVideoMode];
            } else {
                [self.delegate AVDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:101 userInfo:nil]];
            }
            break;
    }
    
    [self.delegate AVModeDidChange:self mode:captureMode];
}

#pragma mark - Private methods

- (void)purgeMode
{
    [self stopSession];
    
    for (AVCaptureInput *input in self.session.inputs) {
        [self.session removeInput:input];
    }
    
    for (AVCaptureOutput *output in self.session.outputs) {
        [self.session removeOutput:output];
    }
    
    [self.preview removeFromSuperlayer];
}

- (void)establishPhotoMode
{
    [self purgeMode];
    
    // Flash & torch support
    // ---------------------------------
    [DIYAVUtilities setFlash:[[self.options valueForKey:DIYAVSettingFlash] boolValue] forCameraInPosition:[[self.options valueForKey:DIYAVSettingCameraPosition] integerValue]];
    
    // Inputs
    // ---------------------------------
    AVCaptureDevice *videoDevice    = [DIYAVUtilities cameraInPosition:[[self.options valueForKey:DIYAVSettingCameraPosition] integerValue]];
    if (videoDevice) {
        NSError *error;
        self.videoInput             = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        [DIYAVUtilities setHighISO:[[self.options valueForKey:DIYAVSettingCameraHighISO] boolValue] forCameraInPosition:[[self.options valueForKey:DIYAVSettingCameraPosition] integerValue]];
        if (!error) {
            if ([self.session canAddInput:self.videoInput]) {
                [self.session addInput:self.videoInput];
            } else {
                [self.delegate AVDidFail:self withError:[NSError errorWithDomain:@"com.diy.av" code:201 userInfo:nil]];
            }
        } else {
            [[self delegate] AVDidFail:self withError:error];
        }
    } else {
        [self.delegate AVDidFail:self withError:[NSError errorWithDomain:@"com.diy.av" code:200 userInfo:nil]];
    }
    
    // Outputs
    // ---------------------------------
    NSDictionary *stillOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    self.stillImageOutput.outputSettings = stillOutputSettings;
    [self.session addOutput:self.stillImageOutput];
    
    // Preset
    // ---------------------------------
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    if ([self.session canSetSessionPreset:[self.options valueForKey:DIYAVSettingPhotoPreset]]) {
        self.session.sessionPreset = [self.options valueForKey:DIYAVSettingPhotoPreset];
    }
    
    // Preview
    // ---------------------------------
    self.preview.videoGravity   = AVLayerVideoGravityResizeAspectFill;
    [self.preview reset];
    [self.delegate AVAttachPreviewLayer:self.preview];
    
    // Start session
    // ---------------------------------
    [self startSession];
}

- (void)establishVideoMode
{
    [self purgeMode];
    
    // Flash & torch support
    // ---------------------------------
    [DIYAVUtilities setFlash:[[self.options valueForKey:DIYAVSettingFlash] boolValue] forCameraInPosition:[[self.options valueForKey:DIYAVSettingCameraPosition] integerValue]];
    
    // Inputs
    // ---------------------------------
    AVCaptureDevice *videoDevice    = [DIYAVUtilities cameraInPosition:[[self.options valueForKey:DIYAVSettingCameraPosition] integerValue]];
    if (videoDevice) {
        NSError *error;
        self.videoInput             = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        [DIYAVUtilities setHighISO:[[self.options valueForKey:DIYAVSettingCameraHighISO] boolValue] forCameraInPosition:[[self.options valueForKey:DIYAVSettingCameraPosition] integerValue]];
        if (!error) {
            if ([self.session canAddInput:self.videoInput]) {
                [self.session addInput:self.videoInput];
            } else {
                [self.delegate AVDidFail:self withError:[NSError errorWithDomain:@"com.diy.av" code:201 userInfo:nil]];
            }
        } else {
            [[self delegate] AVDidFail:self withError:error];
        }
    } else {
        [self.delegate AVDidFail:self withError:[NSError errorWithDomain:@"com.diy.av" code:200 userInfo:nil]];
    }
    
    AVCaptureDevice *audioDevice    = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (audioDevice)
    {
        NSError *error              = nil;
        self.audioInput             = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        if (!error)
        {
            [self.session addInput:self.audioInput];
        } else {
            [self.delegate AVDidFail:self withError:error];
        }
    }
    
    // Outputs
    // ---------------------------------
    Float64 TotalSeconds                            = [[self.options valueForKey:DIYAVSettingVideoMaxDuration] floatValue];			// Max seconds
    int32_t preferredTimeScale                      = [[self.options valueForKey:DIYAVSettingVideoFPS] integerValue];                // Frames per second
    CMTime maxDuration                              = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);
    self.movieFileOutput.maxRecordedDuration        = maxDuration;
    self.movieFileOutput.minFreeDiskSpaceLimit      = DEVICE_DISK_MINIMUM;
    [self.session addOutput:self.movieFileOutput];
    AVCaptureConnection *CaptureConnection          = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
	// Set frame rate (if requried)
	CMTimeShow(CaptureConnection.videoMinFrameDuration);
	CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    
	if (CaptureConnection.supportsVideoMinFrameDuration)
    {
        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, [[self.options valueForKey:DIYAVSettingVideoFPS] integerValue]);
    }
	if (CaptureConnection.supportsVideoMaxFrameDuration)
    {
        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, [[self.options valueForKey:DIYAVSettingVideoFPS] integerValue]);
    }
    
	CMTimeShow(CaptureConnection.videoMinFrameDuration);
	CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    
    // Preset
    // ---------------------------------
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    if ([self.session canSetSessionPreset:[self.options valueForKey:DIYAVSettingVideoPreset]]) {
        self.session.sessionPreset = [self.options valueForKey:DIYAVSettingVideoPreset];
    }
    
    // Preview
    // ---------------------------------
    self.preview.videoGravity   = AVLayerVideoGravityResizeAspectFill;
    [self.preview reset];
    [self.delegate AVAttachPreviewLayer:self.preview];
    
    // Start session
    // ---------------------------------
    [self startSession];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    [self.delegate AVcaptureOutput:captureOutput didFinishRecordingToOutputFileAtURL:outputFileURL shouldSaveToLibrary:[[self.options valueForKey:DIYAVSettingSaveLibrary] boolValue] fromConnections:connections error:error];
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self purgeMode];
    self.delegate = nil;
}

@end
