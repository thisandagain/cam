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
@synthesize orientation;
@synthesize videoInput;
@synthesize audioInput;
@synthesize stillImageOutput;
@synthesize recorder;

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        [self setupSession];
        [self startSession];
    }
    return self;
}

- (void)setupSession
{
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
    
    // I/O
    // ---------------------------------
    AVCaptureDeviceInput *newVideoInput                 = [[AVCaptureDeviceInput alloc] initWithDevice:[self camera] error:nil];
    AVCaptureDeviceInput *newAudioInput                 = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    AVCaptureStillImageOutput *newStillImageOutput  = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [newStillImageOutput setOutputSettings:outputSettings];
    
    [outputSettings release];
    
    // Create session
    // ---------------------------------
    AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    if ([newCaptureSession canAddInput:newVideoInput]) {
        [newCaptureSession addInput:newVideoInput];
    }
    if ([newCaptureSession canAddInput:newAudioInput]) {
        [newCaptureSession addInput:newAudioInput];
    }
    if ([newCaptureSession canAddOutput:newStillImageOutput]) {
        [newCaptureSession addOutput:newStillImageOutput];
    }
    
    [self setStillImageOutput:newStillImageOutput];
    [self setVideoInput:newVideoInput];
    [self setAudioInput:newAudioInput];
    [self setSession:newCaptureSession];
    
    [newStillImageOutput release];
    [newVideoInput release];
    [newAudioInput release];
    [newCaptureSession release];
    
    // Preset
    // ---------------------------------
    if ([newCaptureSession canSetSessionPreset:PHOTO_PRESET])
    {
        [newCaptureSession setSessionPreset:PHOTO_PRESET];
    } else {
        [newCaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    // Preview
    // ---------------------------------
    preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preview.orientation     = [[UIDevice currentDevice] orientation];
    preview.videoGravity    = AVLayerVideoGravityResizeAspectFill;
    
    //
    
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
    if (ORIENTATION_FORCE) {
        [stillImageConnection setVideoOrientation:ORIENTATION_DEFAULT];
    }
    
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection
     completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
         
         [[self delegate] camCaptureStarted:self];
         
         if (imageDataSampleBuffer != NULL) 
         {
             if (ASSET_LIBRARY) {
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
    
}

/**
 * Stop video capture session and save to disk.
 *
 * @return  void
 */
- (void)stopVideoCapture
{
    if (ASSET_LIBRARY) {
        [self performSelectorInBackground:@selector(writeVideoToAssetLibrary:) withObject:nil];
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
    ALAssetsLibrary *library        = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:video completionBlock:^(NSURL *assetURL, NSError *error) {
        NSLog(@"Asset written to library: %@", assetURL);
    }];
    
    // ####
    
    [pool release];
}

#pragma mark - Utility

- (bool)isRecording
{
    return false;
}

#pragma mark - Private methods

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

// Find the specified camera, returning nil if one is not found
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
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"]];
}

- (void)removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] camDidFail:self withError:error];
            }            
        }
    }
}

- (void) copyFileToDocuments:(NSURL *)fileURL
{
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
	NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
	[dateFormatter release];
	NSError	*error;
	if (![[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error]) {
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] camDidFail:self withError:error];
		}
	}
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [session release]; session = nil;
    [preview release]; preview = nil;
    [audioInput release]; audioInput = nil;
    [videoInput release]; videoInput = nil;
    [stillImageOutput release]; stillImageOutput = nil;
    [recorder release]; recorder = nil;
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end