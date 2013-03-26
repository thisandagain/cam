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
@property NSOperationQueue  *queue;
@property DIYAV             *diyAV;
@end

//

@implementation DIYCam

#pragma mark - Init

- (void)_init
{
    // Defaults
    self.backgroundColor    = [UIColor blackColor];

    // Queue
    _queue                  = [[NSOperationQueue alloc] init];
    self.queue.maxConcurrentOperationCount = 4;
    
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
    self.diyAV.delegate     = self;
}

- (BOOL)getRecordingStatus
{
    return self.diyAV.isRecording;
}

- (void)startSession
{
    [self.diyAV startSession];
}

- (void)stopSession
{
    [self.diyAV stopSession];
}

- (DIYAVMode)getCamMode
{
    return self.diyAV.captureMode;
}

- (void)setCamMode:(DIYAVMode)mode
{
    self.captureMode = mode;
}

- (BOOL)getFlash
{
    return self.diyAV.flash;
}

- (void)setFlash:(BOOL)flash
{
    [self.diyAV setFlash:flash];
}

- (void)flipCamera
{
    if (self.diyAV.cameraPosition == AVCaptureDevicePositionFront) {
        self.diyAV.cameraPosition = AVCaptureDevicePositionBack;
    }
    else {
        self.diyAV.cameraPosition = AVCaptureDevicePositionFront;
    }
}

- (void)capturePhoto
{
    [self.diyAV capturePhoto];
}

- (void)captureVideoStart
{
    [self.diyAV captureVideoStart];
}

- (void)captureVideoStop
{
    [self.diyAV captureVideoStop];
}

#pragma mark - DIYAVdelegate

- (void)AVAttachPreviewLayer:(CALayer *)layer
{
    layer.frame = self.frame;
    [self.layer addSublayer:layer];
}


- (void)AVDidFail:(DIYAV *)av withError:(NSError *)error
{
    [self.delegate camDidFail:self withError:error];
}

- (void)AVModeWillChange:(DIYAV *)av mode:(DIYAVMode)mode
{
    [self.delegate camModeWillChange:self mode:mode];
}

- (void)AVModeDidChange:(DIYAV *)av mode:(DIYAVMode)mode
{
    [self.delegate camModeDidChange:self mode:mode];
}

- (void)AVCaptureStarted:(DIYAV *)av
{
    [self.delegate camCaptureStarted:self];
}

- (void)AVCaptureStopped:(DIYAV *)av
{
    [self.delegate camCaptureStopped:self];
}

- (void)AVCaptureOutputStill:(CMSampleBufferRef)imageDataSampleBuffer shouldSaveToLibrary:(BOOL)shouldSaveToLibrary withError:(NSError *)error
{
    [self.delegate camCaptureProcessing:self];
    
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
                [self.delegate camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:fop.path, @"path", @"image", @"type", nil]];
                
                // Save to asset library
                if (shouldSaveToLibrary) {
                    DIYCamLibraryImageOperation *lop = [[DIYCamLibraryImageOperation alloc] initWithData:imageData];
                    [lop setCompletionBlock:^{
                        if (lop.complete) {
                            [self.delegate camCaptureLibraryOperationComplete:self];
                        }
                    }];
                    [self.queue addOperation:lop];
                }
                
            } else {
                [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
            }
        }];
#pragma clang diagnostic pop
        
        [self.queue addOperation:fop];
    } else {
        [self.delegate camDidFail:self withError:error];
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
        [self.delegate camCaptureProcessing:self];
        
        // Thumbnail
        [DIYCamUtilities generateVideoThumbnail:outputFileURL success:^(UIImage *image, NSData *data) {
            DIYCamFileOperation *fOp = [[DIYCamFileOperation alloc] initWithData:data forLocation:DIYCamFileLocationCache];
            
            // Completion block is manually nilled out to break the retain cycle
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-retain-cycles"
            [fOp setCompletionBlock:^{
                if (fOp.complete) {
                    [self.delegate camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:outputFileURL, @"path", @"video", @"type", fOp.path, @"thumb", nil]];

                    if (shouldSaveToLibrary) {
                        DIYCamLibraryVideoOperation *lOp = [[DIYCamLibraryVideoOperation alloc] initWithURL:outputFileURL];
                        [lOp setCompletionBlock:^{
                            if (lOp.complete) {
                                [self.delegate camCaptureLibraryOperationComplete:self];
                            }
                        }];
                        [self.queue addOperation:lOp];
                    }
                } else {
                    [self.delegate camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:500 userInfo:nil]];
                }
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

- (void)setCaptureMode:(DIYAVMode)captureMode
{
    self.diyAV.captureMode = captureMode;
}


#pragma mark - Focusing

- (void)focusAtTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapPoint = [gestureRecognizer locationInView:self];
    [self.diyAV focusAtPoint:tapPoint inFrame:self.frame];
}

#pragma mark - Dealloc

- (void)dealloc
{
    self.delegate = nil;
}

@end
