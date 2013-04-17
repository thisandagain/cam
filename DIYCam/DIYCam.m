//
//  DIYCam.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCam.h"

#import "DIYAV.h"

//

@interface DIYCam ()
{
    NSOperationQueue  *_queue;
    DIYAV             *_diyAV;
}
@end

//

@implementation DIYCam

@synthesize delegate = _delegate;

#pragma mark - Init

- (void)_init
{
    // Defaults
    self.backgroundColor    = [UIColor blackColor];

    // Queue
    _queue                  = [[NSOperationQueue alloc] init];
    _queue.maxConcurrentOperationCount = 4;
    
    // Gesture Recognizer for taps for focus
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAtTap:)];
    [self addGestureRecognizer:tap];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self _init];
    }
    return self;
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

- (void)setupWithOptions:(NSDictionary *)options
{
    if (!options) {
        options = @{};
    }
    _diyAV                  = [[DIYAV alloc] initWithOptions:options];
    _diyAV.delegate     = self;
}

- (BOOL)getRecordingStatus
{
    return _diyAV.isRecording;
}

- (void)startSession
{
    [_diyAV startSession];
}

- (void)stopSession
{
    [_diyAV stopSession];
}

- (DIYAVMode)getCamMode
{
    return _diyAV.captureMode;
}

- (void)setCamMode:(DIYAVMode)mode
{
    _diyAV.captureMode = mode;
}

- (BOOL)getFlash
{
    return _diyAV.flash;
}

- (void)setFlash:(BOOL)flash
{
    [_diyAV setFlash:flash];
}

- (void)flipCamera
{
    if (_diyAV.cameraPosition == AVCaptureDevicePositionFront) {
        _diyAV.cameraPosition = AVCaptureDevicePositionBack;
    }
    else {
        _diyAV.cameraPosition = AVCaptureDevicePositionFront;
    }
}

- (void)capturePhoto
{
    [_diyAV capturePhoto];
}

- (void)captureVideoStart
{
    [_diyAV captureVideoStart];
}

- (void)captureVideoStop
{
    [_diyAV captureVideoStop];
}

#pragma mark - DIYAVdelegate

- (void)AVAttachPreviewLayer:(CALayer *)layer
{
    layer.frame = self.frame;
    [self.layer addSublayer:layer];
}


- (void)AVDidFail:(DIYAV *)av withError:(NSError *)error
{
    [_delegate camDidFail:self withError:error];
}

- (void)AVModeWillChange:(DIYAV *)av mode:(DIYAVMode)mode
{
    [_delegate camModeWillChange:self mode:mode];
}

- (void)AVModeDidChange:(DIYAV *)av mode:(DIYAVMode)mode
{
    [_delegate camModeDidChange:self mode:mode];
}

- (void)AVCaptureStarted:(DIYAV *)av
{
    [_delegate camCaptureStarted:self];
}

- (void)AVCaptureStopped:(DIYAV *)av
{
    [_delegate camCaptureStopped:self];
}

- (void)AVCaptureOutputStill:(CMSampleBufferRef)imageDataSampleBuffer shouldSaveToLibrary:(BOOL)shouldSaveToLibrary withError:(NSError *)error
{
    [_delegate camCaptureProcessing:self];
    
    // Check sample buffer
    if (imageDataSampleBuffer != NULL && error == nil) {
        // Convert to jpeg
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        
        // Save to application cache
        DIYCamFileOperation *fop = [[DIYCamFileOperation alloc] initWithData:imageData forLocation:DIYCamFileLocationCache];
        
        // Completion block is manually nilled out to break the retain cycle
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        [fop setCompletionBlock:^{
            if (fop.complete) {
                [_delegate camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:fop.path, @"path", @"image", @"type", nil]];
                
                // Save to asset library
                if (shouldSaveToLibrary) {
                    DIYCamLibraryImageOperation *lop = [[DIYCamLibraryImageOperation alloc] initWithData:imageData];
                    [lop setCompletionBlock:^{
                        if (lop.complete) {
                            [_delegate camCaptureLibraryOperationComplete:self];
                        }
                    }];
                    [_queue addOperation:lop];
                }
                
            } else {
                [_delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
            }
        }];
#pragma clang diagnostic pop
        
        [_queue addOperation:fop];
    } else {
        [_delegate camDidFail:self withError:error];
    }
}

- (void)AVcaptureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL shouldSaveToLibrary:(BOOL)shouldSaveToLibrary fromConnections:(NSArray *)connections error:(NSError *)error
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
        [_delegate camCaptureProcessing:self];
        
        // Thumbnail
        [DIYCamUtilities generateVideoThumbnail:outputFileURL success:^(UIImage *image, NSData *data) {
            DIYCamFileOperation *fOp = [[DIYCamFileOperation alloc] initWithData:data forLocation:DIYCamFileLocationCache];
            
            // Completion block is manually nilled out to break the retain cycle
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-retain-cycles"
            [fOp setCompletionBlock:^{
                if (fOp.complete) {
                    [_delegate camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:outputFileURL, @"path", @"video", @"type", fOp.path, @"thumb", nil]];

                    if (shouldSaveToLibrary) {
                        DIYCamLibraryVideoOperation *lOp = [[DIYCamLibraryVideoOperation alloc] initWithURL:outputFileURL];
                        [lOp setCompletionBlock:^{
                            if (lOp.complete) {
                                [_delegate camCaptureLibraryOperationComplete:self];
                            }
                        }];
                        [_queue addOperation:lOp];
                    }
                } else {
                    [_delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
                }
            }];
            #pragma clang diagnostic pop
            
            [_queue addOperation:fOp];
        } failure:^(NSException *exception) {
            [_delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
        }];
        
	} else {
        [[self delegate] camDidFail:self withError:error];
    }
}

#pragma mark - Focusing

- (void)focusAtTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapPoint = [gestureRecognizer locationInView:self];
    [_diyAV focusAtPoint:tapPoint inFrame:self.frame];
}

#pragma mark - Dealloc

- (void)dealloc
{
    self.delegate = nil;
}

@end
