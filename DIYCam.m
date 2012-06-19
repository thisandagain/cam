//
//  DIYCam.m
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCam.h"

//

@interface DIYCam ()
@property (nonatomic, assign) AVCaptureDeviceInput *videoInput;
@property (nonatomic, assign) AVCaptureDeviceInput *audioInput;

@property (atomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (atomic, retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (atomic, retain) ALAssetsLibrary *library;
@end

//

@implementation DIYCam

@synthesize delegate;
@synthesize session;
@synthesize preview;
@synthesize isRecording;
@synthesize videoInput;
@synthesize audioInput;
@synthesize stillImageOutput;
@synthesize movieFileOutput;
@synthesize library;

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self != nil) 
    {
        library        = [[ALAssetsLibrary alloc] init];
    }
    
    return self;
}

/**
 * Instanciates session and camera IO.
 *
 * @return  void
 */
- (void)setup
{
    if ([self isVideoCameraAvailable])
    {
        // Create session state
        // ---------------------------------
        session         = [[AVCaptureSession alloc] init];
        [self setIsRecording:false];
        
        // Flash & torch support
        // ---------------------------------
        if ([[self camera] hasFlash]) 
        {
            if ([[self camera] lockForConfiguration:nil]) 
            {
                if (DEVICE_FLASH) 
                {
                    if ([[self camera] isFlashModeSupported:AVCaptureFlashModeAuto]) {
                        [[self camera] setFlashMode:AVCaptureFlashModeAuto];
                    }
                } else {
                    if ([[self camera] isFlashModeSupported:AVCaptureFlashModeOff]) {
                        [[self camera] setFlashMode:AVCaptureFlashModeOff];
                    }
                }
                [[self camera] unlockForConfiguration];
            }
        }
        if ([[self camera] hasTorch]) 
        {
            if ([[self camera] lockForConfiguration:nil]) 
            {
                if (DEVICE_FLASH)
                {
                    if ([[self camera] isTorchModeSupported:AVCaptureTorchModeAuto]) 
                    {
                        [[self camera] setTorchMode:AVCaptureTorchModeAuto];
                    }
                } else {
                    if ([[self camera] isTorchModeSupported:AVCaptureTorchModeOff]) 
                    {
                        [[self camera] setTorchMode:AVCaptureTorchModeOff];
                    }
                }
                [[self camera] unlockForConfiguration];
            }
        }
        
        // Inputs
        // ---------------------------------
        AVCaptureDevice *videoDevice    = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (videoDevice)
        {
            NSError *error;
            videoInput                  = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
            if (!error)
            {
                if ([session canAddInput:videoInput])
                {
                    [session addInput:videoInput];
                } else {
                    NSLog(@"Error: Couldn't add video input");
                }
            } else {
                [[self delegate] camDidFail:self withError:error];
            }
        } else {
            NSLog(@"Error: Couldn't create video capture device");
        }
        
        AVCaptureDevice *audioDevice    = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        if (audioDevice)
        {
            NSError *error              = nil;
            audioInput                  = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            if (!error)
            {
                [session addInput:audioInput];
            } else {
                [[self delegate] camDidFail:self withError:error];
            }
        }
        
        // Outputs
        // ---------------------------------
        stillImageOutput                        = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *stillOutputSettings       = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [stillImageOutput setOutputSettings:stillOutputSettings];
        [session addOutput:stillImageOutput];
        [stillOutputSettings release];
        
        //
        
        movieFileOutput                         = [[AVCaptureMovieFileOutput alloc] init];
        Float64 TotalSeconds                    = VIDEO_DURATION;			// Max seconds
        int32_t preferredTimeScale              = VIDEO_FPS;                // Frames per second
        CMTime maxDuration                      = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);
        movieFileOutput.maxRecordedDuration     = maxDuration;
        movieFileOutput.minFreeDiskSpaceLimit   = VIDEO_MIN_DISK;
        [session addOutput:movieFileOutput];
        [self setOutputProperties];
        
        // Preset
        // ---------------------------------
        [session setSessionPreset:AVCaptureSessionPresetMedium];
        if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720])
        {
            [session setSessionPreset:AVCaptureSessionPreset1280x720];
        }
        
        // Preview
        // ---------------------------------
        preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
        preview.videoGravity    = AVLayerVideoGravityResizeAspectFill;
        if (ORIENTATION_FORCE) {
            preview.orientation = ORIENTATION_OVERRIDE;
        } else {
            preview.orientation = [[UIDevice currentDevice] orientation];
        }
        
        // Start session
        // ---------------------------------
        [self startSession];
        [[self delegate] camReady:self];
    }
}

- (void)startSession
{
    if (session != nil)
    {
        [session startRunning];
    }
}

- (void)stopSession
{
    if (session != nil)
    {
        [session stopRunning];
    }
}

#pragma mark - Photo

/**
 * Capture a photo and save to disk.
 *
 * @return  void
 */
- (void)startPhotoCapture
{
    if (session != nil)
    {
        AVCaptureConnection *stillImageConnection = [DIYCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
        if (ORIENTATION_FORCE) 
        {
            [stillImageConnection setVideoOrientation:ORIENTATION_DEFAULT];
        }
        
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) 
         {
             [[self delegate] camCaptureProcessing:self];
             
             if (imageDataSampleBuffer != NULL) 
             {
                 if (ASSET_LIBRARY) 
                 {
                     [self performSelectorInBackground:@selector(writePhotoToAssetLibrary:) withObject:(id)imageDataSampleBuffer];
                 }
                 [self performSelectorInBackground:@selector(writePhotoToFileSystem:) withObject:(id)imageDataSampleBuffer];
             } else {
                 [[self delegate] camDidFail:self withError:error];
             }
         }];
    }
}

/**
 * Writes sample buffer to asset library.
 *
 * @param  CMSampleBufferRef  Image buffer
 *
 * @return  void
 */
- (void)writePhotoToAssetLibrary:(CMSampleBufferRef)imageDataSampleBuffer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // ####
    
    // Image data
    NSData *imageData               = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
    
    // Asset library
    [library writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        NSLog(@"Asset written to library: %@", assetURL);
    }];

    // ####
    
    [pool release];
}

/**
 * Writes sample buffer to local file-system.
 *
 * @param  CMSampleBufferRef  Image buffer
 *
 * @return  void
 */
- (void)writePhotoToFileSystem:(CMSampleBufferRef)imageDataSampleBuffer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // ####
    
    // Image data
    NSData *imageData               = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
    
    // Scale image
    UIImage *image                  = [[UIImage alloc] initWithData:imageData];
    NSData *scaledImageData         = UIImageJPEGRepresentation([image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(PHOTO_WIDTH, PHOTO_HEIGHT) interpolationQuality:PHOTO_INTERPOLATION], PHOTO_QUALITY);
    
    // Documents
    NSString *assetPath             = [self createAssetFilePath:@"jpg"];
    [scaledImageData writeToFile:assetPath atomically:true];
    
    // Complete delegate
    [[self delegate] camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        assetPath, @"path",
                                                        @"image", @"type",
                                                        nil]];
    
    // GC
    [image release];
    
    // ####
    
    [pool release];
}

#pragma mark - Video

/**
 * Start a video capture session.
 *
 * @return  void
 */
- (void)startVideoCapture
{    
    if (session != nil)
    {
        [self setIsRecording:true];
        [[self delegate] camCaptureStarted:self];
        
        // Create URL to record to
        NSString *assetPath         = [self createAssetFilePath:@"mov"];
        NSURL *outputURL            = [[NSURL alloc] initFileURLWithPath:assetPath];
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
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        [outputURL release];
    }
}

/**
 * Stop video capture session and save to disk.
 *
 * @return  void
 */
- (void)stopVideoCapture
{
    if (session != nil && self.isRecording)
    {
        [self setIsRecording:false];
        [[self delegate] camCaptureStopped:self];
        
        [movieFileOutput stopRecording];
    }
}

/**
 * Persist video to asset library.
 *
 * @param  NSURL  Asset path
 *
 * @return  void
 */
- (void)writeVideoToAssetLibrary:(NSURL *)video
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // ####
        
    // Asset library
    [library writeVideoAtPathToSavedPhotosAlbum:video completionBlock:^(NSURL *assetURL, NSError *error) {
        NSLog(@"Asset written to library: %@", assetURL);
    }];
    
    // ####
    
    [pool release];
}

/**
 * Return the video asset information.
 *
 * @param  NSURL  Asset path
 *
 * @return  void
 */
- (void)writeVideoToFileSystem:(NSURL *)video
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // ####
    
    [self generateVideoThumbnail:[video absoluteString] success:^(UIImage *image, NSURL *thumbnail) {
        [[self delegate] camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            [video absoluteString], @"path",
                                                            [thumbnail absoluteString], @"thumbnail",
                                                            @"video", @"type",
                                                            nil]];
    } failure:^(NSException *exception) {
        [[self delegate] camDidFail:self withError:[NSError errorWithDomain:@"com.diy.cam" code:0 userInfo:nil]];
    }];
    
    // ####
    
    [pool release];
}

#pragma mark - Utilities

- (NSString *)createAssetFilePath:(NSString *)extension
{
    NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory    = [paths objectAtIndex:0];
    NSString *assetName             = [NSString stringWithFormat:@"%@.%@", [[NSProcessInfo processInfo] globallyUniqueString], extension];
    NSString *assetPath             = [documentsDirectory stringByAppendingPathComponent:assetName];
    
    return assetPath;
}

#pragma mark - Private methods

- (void) setOutputProperties
{
	AVCaptureConnection *CaptureConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
	// Set landscape (if required)
	if ([CaptureConnection isVideoOrientationSupported])
	{
		AVCaptureVideoOrientation orientation = ORIENTATION_DEFAULT;
		[CaptureConnection setVideoOrientation:orientation];
	}
    
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
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)camera
{
    return [self cameraWithPosition:DEVICE_PRIMARY];
}

- (BOOL)isVideoCameraAvailable
{
	UIImagePickerController *picker     = [[UIImagePickerController alloc] init];
	NSArray *sourceTypes                = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
	[picker release];
    
	if (![sourceTypes containsObject:(NSString *)kUTTypeMovie])
    {
		return false;
	}
    
	return true;
}

- (void)generateVideoThumbnail:(NSString*)url success:(void (^)(UIImage *image, NSURL *path))success failure:(void (^)(NSException *exception))failure
{
    // Setup
    AVURLAsset *asset                           = [[[AVURLAsset alloc] initWithURL:[NSURL URLWithString:url] options:nil] autorelease];
    CMTime thumbTime                            = CMTimeMakeWithSeconds(0,24);
    
    AVAssetImageGenerator *generator            = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform    = false;
    generator.maximumSize = CGSizeMake(PHOTO_WIDTH, PHOTO_HEIGHT);
    
    // Completion handler
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            failure([NSException exceptionWithName:@"" reason:@"Could not generate video thumbnail" userInfo:nil]);
        } else {
            success([UIImage imageWithCGImage:im], nil);
        }
        
        [generator release];
    };
    
    // Generate
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    BOOL RecordedSuccessfully = true;
    
    if ([error code] != noErr)
	{
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
		{
            RecordedSuccessfully = [value boolValue];
        }
    }
    
	if (RecordedSuccessfully)
	{
        if (ASSET_LIBRARY) 
        {
            [self performSelectorInBackground:@selector(writeVideoToAssetLibrary:) withObject:outputFileURL];
        }
        [self performSelectorInBackground:@selector(writeVideoToFileSystem:) withObject:outputFileURL];
	} else {
        [[self delegate] camDidFail:self withError:error];
    }
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [[self session] stopRunning];
    
    delegate = nil;
    
    [session release]; session = nil;
    [stillImageOutput release]; stillImageOutput = nil;
    [movieFileOutput release]; movieFileOutput = nil;
    [library release]; library = nil;
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end