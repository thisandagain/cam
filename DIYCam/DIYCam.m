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
@property (assign, readwrite) BOOL isRecording;
@property NSOperationQueue *queue;
@property DIYAV *diyAV;
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
    [self.diyAV startSession];
}

- (void)stopSession
{
    [self.diyAV stopSession];
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

- (void)AVCaptureOutputStill:(CMSampleBufferRef)imageDataSampleBuffer withError:(NSError *)error
{
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
    [self purgeMode];
    self.delegate = nil;
}

@end
