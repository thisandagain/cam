//
//  DIYCam.m
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCam.h"

@implementation DIYCam

@synthesize delegate;
@synthesize session;
@synthesize preview;
@synthesize videoInput;
@synthesize audioInput;
@synthesize stillImageOutput;
@synthesize movieFileOutput;
@synthesize backgroundRecordingID;

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self != nil) 
    {
        //
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
    // Create session state
    // ---------------------------------
    session         = [[AVCaptureSession alloc] init];
    isRecording     = false;
    
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
    stillImageOutput                = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings    = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    [session addOutput:stillImageOutput];
    [outputSettings release];
    
    //
    
    movieFileOutput                 = [[AVCaptureMovieFileOutput alloc] init];
    Float64 TotalSeconds            = 120;			// Max seconds
	int32_t preferredTimeScale      = 30;           // Frames per second
	CMTime maxDuration              = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);
	movieFileOutput.maxRecordedDuration     = maxDuration;
	movieFileOutput.minFreeDiskSpaceLimit   = 48828 * 1024;
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
    preview.orientation     = [[UIDevice currentDevice] orientation];
    preview.videoGravity    = AVLayerVideoGravityResizeAspectFill;
    
    // Start session
    // ---------------------------------
    [self startSession];
    [[self delegate] camReady:self];
}

- (void)startSession
{
    [session startRunning];
}

- (void)stopSession
{
    [session stopRunning];
}

#pragma mark - Photo

/**
 * Capture a photo and save to disk.
 *
 * @return  void
 */
- (void)startPhotoCapture
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
    ALAssetsLibrary *library        = [[ALAssetsLibrary alloc] init];
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
    NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory    = [paths objectAtIndex:0];
    NSString *assetName             = [NSString stringWithFormat:@"%@.jpg", [[NSProcessInfo processInfo] globallyUniqueString]];
    NSString *assetPath             = [documentsDirectory stringByAppendingPathComponent:assetName];
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
    isRecording = true;
    [[self delegate] camCaptureStarted:self];
    
    //Create temporary URL to record to
    NSString *outputPath        = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL            = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            [[self delegate] camDidFail:self withError:error];
        }
    }
    [outputPath release];
    
    //Start recording
    [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    [outputURL release];
}

/**
 * Stop video capture session and save to disk.
 *
 * @return  void
 */
- (void)stopVideoCapture
{
    isRecording = false;
    [[self delegate] camCaptureStopped:self];
    
    [movieFileOutput stopRecording];
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
    ALAssetsLibrary *library        = [[ALAssetsLibrary alloc] init];
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
        
    [[self delegate] camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [video absoluteString], @"path",
                                                        @"video", @"type",
                                                        nil]];
    
    // ####
    
    [pool release];
}

#pragma mark - Utility

- (bool)isRecording
{
    return isRecording;
}

#pragma mark - Private methods

- (void) setOutputProperties
{
	AVCaptureConnection *CaptureConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
	// Set landscape (if required)
	if ([CaptureConnection isVideoOrientationSupported])
	{
		AVCaptureVideoOrientation orientation = ORIENTATION_DEFAULT;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
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

- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) {
        return [devices objectAtIndex:0];
    }
    return nil;
}

- (NSURL *)tempFileURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"iphone.mov"]];
}

- (void)removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            [[self delegate] camDidFail:self withError:error];
        }
    }
}

- (void)copyFileToDocuments:(NSURL *)fileURL
{
	NSString *documentsDirectory        = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDateFormatter *dateFormatter      = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
	NSString *destinationPath           = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
	[dateFormatter release];
	
    NSError	*error;
	if (![[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error]) {
        [[self delegate] camDidFail:self withError:error];
	}
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
        [[self delegate] camCaptureComplete:self withAsset:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                @"image", @"type",
                                                                outputFileURL, @"path"
                                                                , nil]];
        
		ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
		if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
		{
			[library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
										completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 if (error)
                 {
                     
                 }
             }];
		}
        
		[library release];		
	}
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [[self session] stopRunning];
    
    [session release]; session = nil;
    [preview release]; preview = nil;
    [audioInput release]; audioInput = nil;
    [videoInput release]; videoInput = nil;
    [stillImageOutput release]; stillImageOutput = nil;
    [movieFileOutput release]; movieFileOutput = nil;
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end