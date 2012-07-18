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
        
        [self.delegate camCaptureStarted:self];
        
        // Capture image async block
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {             
            
            [self.delegate camCaptureProcessing:self];
            
            // Check sample buffer 
            if (imageDataSampleBuffer != NULL && error == nil) {
                // Convert to jpeg
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                 
                // Save to asset library
                if (SAVE_ASSET_LIBRARY) {
                    DIYCamLibraryOperation *lop = [[DIYCamLibraryOperation alloc] initWithData:imageData];
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
    
}

- (void)captureVideoStop
{
    
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
    self.preview.videoGravity   = PHOTO_SESSION_GRAVITY;
    self.preview.frame          = self.frame;
    [self.layer addSublayer:self.preview];
    
    // Start session
    // ---------------------------------
    [self startSession];
}

- (void)establishVideoMode
{
    [self purgeMode];
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
