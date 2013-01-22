//
//  DIYCam.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCam.h"

//

@interface DIYCam ()
@property (assign, readwrite) BOOL isRecording;
@property NSOperationQueue *queue;
@property DIYCamPreview *preview;
@property (nonatomic) DIYCamMode captureMode;

@property AVCaptureSession *session;
@property AVCaptureDeviceInput *videoInput;
@property AVCaptureDeviceInput *audioInput;
@property AVCaptureStillImageOutput *stillImageOutput;
@property AVCaptureMovieFileOutput *movieFileOutput;

@end

//

@implementation DIYCam

#pragma mark - Init

- (void)_init
{
    // Defaults
    self.backgroundColor    = [UIColor blackColor];
    
    // Properties
    _captureMode            = DIYCamModePhoto;
    _session                = [[AVCaptureSession alloc] init];

    _queue                  = [[NSOperationQueue alloc] init];
    self.queue.maxConcurrentOperationCount = 4;
    _preview                = [[DIYCamPreview alloc] initWithSession:_session];
    _videoInput             = nil;
    _audioInput             = nil;
    _stillImageOutput       = [[AVCaptureStillImageOutput alloc] init];
    _movieFileOutput        = [[AVCaptureMovieFileOutput alloc] init];
        
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAtTap:)];
    [self addGestureRecognizer:tap];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

#pragma mark - Public methods

- (BOOL)getRecordingStatus
{
    return self.isRecording;
}

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

- (DIYCamMode)getCamMode
{
    return self.captureMode;
}

- (void)setCamMode:(DIYCamMode)mode
{
    self.captureMode = mode;
}

- (void)capturePhoto
{
    if (self.session != nil) {
        
        // Connection
        AVCaptureConnection *stillImageConnection = [DIYCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
        if (DEVICE_ORIENTATION_FORCE) {
            stillImageConnection.videoOrientation = DEVICE_ORIENTATION_DEFAULT;
        } else {
            stillImageConnection.videoOrientation = [[UIDevice currentDevice] orientation];
        }
        
        // Capture image async block
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {             
            
            [self.delegate camCaptureProcessing:self];
            
            // Check sample buffer 
            if (imageDataSampleBuffer != NULL && error == nil) {
                // Convert to jpeg
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                 
                // Save to asset library
                if (SAVE_ASSET_LIBRARY) {
                    DIYCamLibraryImageOperation *lop = [[DIYCamLibraryImageOperation alloc] initWithData:imageData];
                    [self.queue addOperation:lop];
                }
                 
                // Save to application cache
                DIYCamFileOperation *fop = [[DIYCamFileOperation alloc] initWithData:imageData forLocation:DIYCamFileLocationCache];
                
                // Completion block is manually nilled out to break the retain cycle 
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-retain-cycles"
                [fop setCompletionBlock:^{
                    if (fop.complete) {
                        [self.delegate camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:fop.path, @"path", @"image", @"type", nil]];
                    } else {
                        [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
                    }
                    [fop setCompletionBlock:nil];
                }];
                #pragma clang diagnostic pop
                
                [self.queue addOperation:fop];
             } else {
                 [self.delegate camDidFail:self withError:error];
             }
         }];
    } else {
        [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
    }
}

- (void)captureVideoStart
{
    if (self.session != nil) {
        [self setIsRecording:true];
        [self.delegate camCaptureStarted:self];
        
        // Create URL to record to
        NSString *assetPath         = [DIYCamUtilities createAssetFilePath:@"mov"];
        NSURL *outputURL            = [[NSURL alloc] initFileURLWithPath:assetPath];
        NSFileManager *fileManager  = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:assetPath]) {
            NSError *error;
            if ([fileManager removeItemAtPath:assetPath error:&error] == NO) {
                [[self delegate] camDidFail:self withError:error];
            }
        }
        
        // Record in the correct orientation
        AVCaptureConnection *videoConnection = [DIYCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.movieFileOutput connections]];
        if ([videoConnection isVideoOrientationSupported] && !DEVICE_ORIENTATION_FORCE) {
            [videoConnection setVideoOrientation:[DIYCamUtilities getAVCaptureOrientationFromDeviceOrientation]];
        } else {
            [videoConnection setVideoOrientation:DEVICE_ORIENTATION_DEFAULT];
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
        [self.delegate camCaptureStopped:self];
        
        [self.movieFileOutput stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    BOOL recordedSuccessfully = true;
    
    if ([error code] != noErr) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    
	if (recordedSuccessfully)
	{
        [self.delegate camCaptureProcessing:self];
        
        // Asset library
        if (SAVE_ASSET_LIBRARY) {  
            DIYCamLibraryVideoOperation *lOp = [[DIYCamLibraryVideoOperation alloc] initWithURL:outputFileURL];
            [self.queue addOperation:lOp];
        }
        
        // Thumbnail
        [DIYCamUtilities generateVideoThumbnail:outputFileURL success:^(UIImage *image, NSData *data) {
            DIYCamFileOperation *fOp = [[DIYCamFileOperation alloc] initWithData:data forLocation:DIYCamFileLocationCache];
            
            // Completion block is manually nilled out to break the retain cycle
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-retain-cycles"
            [fOp setCompletionBlock:^{
                if (fOp.complete) {
                    [self.delegate camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:outputFileURL, @"path", @"video", @"type", fOp.path, @"thumb", nil]];
                } else {
                    [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
                }
                [fOp setCompletionBlock:nil];
            }];
            #pragma clang diagnostic pop
            
            [self.queue addOperation:fOp];
        } failure:^(NSException *exception) {
            [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
        }];
        
	} else {
        [[self delegate] camDidFail:self withError:error];
    }
}


#pragma mark - Override

- (void)setCaptureMode:(DIYCamMode)captureMode
{
    // Super
    self->_captureMode = captureMode;
    
    //
    
    [self.delegate camModeWillChange:self mode:captureMode];
    
    switch (captureMode) {
            // Photo mode
            // -------------------------------------
        case DIYCamModePhoto:
            if ([DIYCamUtilities isPhotoCameraAvailable]) {
                [self establishPhotoMode];
            } else {
                [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:100 userInfo:nil]];
            }
            break;
            
            // Video mode
            // -------------------------------------
        case DIYCamModeVideo:
            if ([DIYCamUtilities isVideoCameraAvailable]) {
                [self establishVideoMode];
            } else {
                [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:101 userInfo:nil]];
            }
            break;
    }
        
    [self.delegate camModeDidChange:self mode:captureMode];
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
    [DIYCamUtilities setFlash:DEVICE_FLASH];
    
    // Inputs
    // ---------------------------------
    AVCaptureDevice *videoDevice    = [DIYCamUtilities camera];
    if (videoDevice) {
        NSError *error;
        self.videoInput             = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        [DIYCamUtilities setHighISO:DEVICE_HI_ISO];
        if (!error) {
            if ([self.session canAddInput:self.videoInput]) {
                [self.session addInput:self.videoInput];
            } else {
                [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:201 userInfo:nil]];
            }
        } else {
            [[self delegate] camDidFail:self withError:error];
        }
    } else {
        [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:200 userInfo:nil]];
    }
    
    // Outputs
    // ---------------------------------
    NSDictionary *stillOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    self.stillImageOutput.outputSettings = stillOutputSettings;
    [self.session addOutput:self.stillImageOutput];
    
    // Preset
    // ---------------------------------
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    if ([self.session canSetSessionPreset:PHOTO_SESSION_PRESET]) {
        self.session.sessionPreset = PHOTO_SESSION_PRESET;
    }
    
    // Preview
    // ---------------------------------
    self.preview.videoGravity   = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame          = self.frame;
    [self.preview reset];
    [self.layer addSublayer:self.preview];
    
    // Start session
    // ---------------------------------
    [self startSession];
}

- (void)establishVideoMode
{
    [self purgeMode];
    
    // Flash & torch support
    // ---------------------------------
    [DIYCamUtilities setFlash:DEVICE_FLASH];
    
    // Inputs
    // ---------------------------------
    AVCaptureDevice *videoDevice    = [DIYCamUtilities camera];
    if (videoDevice) {
        NSError *error;
        self.videoInput             = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        [DIYCamUtilities setHighISO:DEVICE_HI_ISO];
        if (!error) {
            if ([self.session canAddInput:self.videoInput]) {
                [self.session addInput:self.videoInput];
            } else {
                [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:201 userInfo:nil]];
            }
        } else {
            [[self delegate] camDidFail:self withError:error];
        }
    } else {
        [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:200 userInfo:nil]];
    }
    
    AVCaptureDevice *audioDevice    = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (audioDevice)
    {
        NSError *error              = nil;
        self.audioInput                  = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        if (!error)
        {
            [self.session addInput:self.audioInput];
        } else {
            [self.delegate camDidFail:self withError:error];
        }
    }
    
    // Outputs
    // ---------------------------------
    Float64 TotalSeconds                    = VIDEO_MAX_DURATION;			// Max seconds
    int32_t preferredTimeScale              = VIDEO_FPS;                // Frames per second
    CMTime maxDuration                      = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);
    self.movieFileOutput.maxRecordedDuration     = maxDuration;
    self.movieFileOutput.minFreeDiskSpaceLimit   = DEVICE_DISK_MINIMUM;
    [self.session addOutput:self.movieFileOutput];
    AVCaptureConnection *CaptureConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
	// Set frame rate (if requried)
	CMTimeShow(CaptureConnection.videoMinFrameDuration);
	CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    
	if (CaptureConnection.supportsVideoMinFrameDuration)
    {
        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, VIDEO_FPS);
    }
	if (CaptureConnection.supportsVideoMaxFrameDuration)
    {
        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, VIDEO_FPS);
    }
    
	CMTimeShow(CaptureConnection.videoMinFrameDuration);
	CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    
    // Preset
    // ---------------------------------
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    if ([self.session canSetSessionPreset:VIDEO_SESSION_PRESET]) {
        self.session.sessionPreset = VIDEO_SESSION_PRESET;
    }
    
    // Preview
    // ---------------------------------
    self.preview.videoGravity   = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame          = self.frame;
    [self.preview reset];
    [self.layer addSublayer:self.preview];
    
    // Start session
    // ---------------------------------
    [self startSession];
}

#pragma mark - Focusing

- (void)focusAtTap:(UIGestureRecognizer *)gestureRecognizer
{  
    if (self.videoInput.device.isFocusPointOfInterestSupported && [self.videoInput.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:self];
        CGPoint focusPoint = [DIYCamUtilities convertToPointOfInterestFromViewCoordinates:tapPoint withFrame:self.frame withPreview:self.preview withPorts:self.videoInput.ports];
        NSError *error;
        if ([self.videoInput.device lockForConfiguration:&error]) {
            self.videoInput.device.focusPointOfInterest = focusPoint;
            self.videoInput.device.focusMode = AVCaptureFocusModeAutoFocus;
            [self.videoInput.device unlockForConfiguration];
        }
        else {
            [self.delegate camDidFail:self withError:error];
        }
    }
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self purgeMode];
    self.delegate = nil;
}

@end
