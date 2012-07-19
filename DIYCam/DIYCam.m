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
@property (nonatomic, assign) BOOL ready;
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) DIYCamPreview *preview;

@property (atomic, retain) AVCaptureDeviceInput *videoInput;
@property (atomic, retain) AVCaptureDeviceInput *audioInput;
@property (atomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (atomic, retain) AVCaptureMovieFileOutput *movieFileOutput;
@end

//

@implementation DIYCam

@synthesize delegate = _delegate;
@synthesize captureMode = _captureMode;
@synthesize session = _session;
@synthesize isRecording = _isRecording;

@synthesize ready = _ready;
@synthesize queue = _queue;
@synthesize preview = _preview;
@synthesize videoInput = _videoInput;
@synthesize audioInput = _audioInput;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize movieFileOutput = _movieFileOutput;

#pragma mark - Init

- (void)_init
{
    // Defaults
    self.backgroundColor    = [UIColor blackColor];
    
    // Properties
    _captureMode            = DIYCamModePhoto;
    _session                = [[AVCaptureSession alloc] init];

    _ready                  = false;
    _queue                  = [[NSOperationQueue alloc] init];
    self.queue.maxConcurrentOperationCount = 4;
    _preview                = [[DIYCamPreview alloc] initWithSession:_session];
    _videoInput             = nil;
    _audioInput             = nil;
    _stillImageOutput       = [[AVCaptureStillImageOutput alloc] init];
    _movieFileOutput        = [[AVCaptureMovieFileOutput alloc] init];
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
                    [lop release];
                }
                 
                // Save to application cache
                DIYCamFileOperation *fop = [[DIYCamFileOperation alloc] initWithData:imageData forLocation:DIYCamFileLocationCache];
                [fop setCompletionBlock:^{
                    if (fop.complete) {
                        [self.delegate camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:fop.path, @"path", @"photo", @"type", nil]];
                    } else {
                        [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
                    }
                    [fop setCompletionBlock:nil];
                }];
                [self.queue addOperation:fop];
                [fop release];
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
        NSURL *outputURL            = [[[NSURL alloc] initFileURLWithPath:assetPath] autorelease];
        NSFileManager *fileManager  = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:assetPath])
        {
            NSError *error;
            if ([fileManager removeItemAtPath:assetPath error:&error] == NO)
            {
                [[self delegate] camDidFail:self withError:error];
            }
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
    
    if ([error code] != noErr)
	{
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
		{
            recordedSuccessfully = [value boolValue];
        }
    }
    
	if (recordedSuccessfully)
	{
        [self.delegate camCaptureProcessing:self];
        if (SAVE_ASSET_LIBRARY) 
        {  
            DIYCamLibraryVideoOperation *lOp = [[DIYCamLibraryVideoOperation alloc] initWithURL:outputFileURL];
            [self.queue addOperation:lOp];
            [lOp release];
        }
        // TODO: write a thumbnail and call complete when done
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
    AVCaptureDevice *videoDevice    = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice) {
        NSError *error;
        self.videoInput             = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
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
    [stillOutputSettings release];
    
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
    AVCaptureDevice *videoDevice    = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice) {
        NSError *error;
        self.videoInput             = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
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
    [self.layer addSublayer:self.preview];
    
    // Start session
    // ---------------------------------
    [self startSession];
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

#pragma mark - Dealloc

- (void)releaseObjects
{
    [self purgeMode];
    _delegate = nil;
    
    [_session release]; _session = nil;
    [_queue release]; _queue = nil;
    [_preview release]; _preview = nil;
    [_videoInput release]; _videoInput = nil;
    [_audioInput release]; _audioInput = nil;
    [_stillImageOutput release]; _stillImageOutput = nil;
    [_movieFileOutput release]; _movieFileOutput = nil;
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end
