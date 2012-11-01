//
//  DIYCamUtilities.m
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamDefaults.h"
#import "DIYCamUtilities.h"

@implementation DIYCamUtilities

#pragma mark - General

+ (AVCaptureDevice *)camera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == DEVICE_POSITION) {
            return device;
        }
    }
    
    return nil;
}

+ (BOOL)isPhotoCameraAvailable
{    
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		return true;
	}
    
	return false;
}

+ (BOOL)isVideoCameraAvailable
{    
	UIImagePickerController *picker     = [[UIImagePickerController alloc] init];
	NSArray *sourceTypes                = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
	[picker release];
    
	if ([sourceTypes containsObject:(NSString *)kUTTypeMovie]) {
		return true;
	}
    
	return false;
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
    
	return nil;
}

#pragma mark - Device setup

+ (void)setFlash:(BOOL)flash
{
    // Flash
    if ([[self camera] hasFlash]) {
        if ([[self camera] lockForConfiguration:nil]) {
            if (flash) {
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
    
    // Torch
    if ([[self camera] hasTorch]) {
        if ([[self camera] lockForConfiguration:nil]) {
            if (flash)
            {
                if ([[self camera] isTorchModeSupported:AVCaptureTorchModeAuto]) {
                    [[self camera] setTorchMode:AVCaptureTorchModeAuto];
                }
            } else {
                if ([[self camera] isTorchModeSupported:AVCaptureTorchModeOff]) {
                    [[self camera] setTorchMode:AVCaptureTorchModeOff];
                }
            }
            [[self camera] unlockForConfiguration];
        }
    }
}

+ (void)setHighISO:(BOOL)highISO
{
    if ([[self camera] respondsToSelector:@selector(isLowLightBoostSupported)]) {
        if ([[self camera] lockForConfiguration:nil]) {
            [self camera].automaticallyEnablesLowLightBoostWhenAvailable = highISO;
            [[self camera] unlockForConfiguration];
        }
    }
}

#pragma mark - Asset helpers

+ (NSString *)createAssetFilePath:(NSString *)extension
{
    NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory    = [paths objectAtIndex:0];
    NSString *assetName             = [NSString stringWithFormat:@"%@.%@", [[NSProcessInfo processInfo] globallyUniqueString], extension];
    NSString *assetPath             = [documentsDirectory stringByAppendingPathComponent:assetName];
    
    return assetPath;
}

+ (void)generateVideoThumbnail:(NSURL *)url success:(void (^)(UIImage *image, NSData *data))success failure:(void (^)(NSException *exception))failure
{
    // Setup
    AVURLAsset *asset                   = [[AVURLAsset alloc] initWithURL:url options:nil];
    Float64 durationSeconds             = CMTimeGetSeconds([asset duration]);
    CMTime thumbTime                    = CMTimeMakeWithSeconds(durationSeconds / 2.0, 600);
    
    // Generate
    AVAssetImageGenerator *thumbnailGenerator   = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    thumbnailGenerator.maximumSize              = CGSizeMake(1280, 720);
    [thumbnailGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        NSString *requestedTimeString = (NSString *)CMTimeCopyDescription(NULL, requestedTime);
        NSString *actualTimeString = (NSString *)CMTimeCopyDescription(NULL, actualTime);
        [requestedTimeString release];
        [actualTimeString release];
        
        //
        
        if (result != AVAssetImageGeneratorSucceeded) 
        {
            failure([NSException exceptionWithName:@"" reason:@"Could not generate video thumbnail" userInfo:nil]);
        } else {
            UIImage *sim = [UIImage imageWithCGImage:im];
            NSData *data = UIImageJPEGRepresentation(sim, 0.7);
            success(sim, data);
        }
        
        [asset release];
        [thumbnailGenerator release];
    }];
}

+ (AVCaptureVideoOrientation)getAVCaptureOrientationFromDeviceOrientation
{  
    AVCaptureVideoOrientation orientation;
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;            
        default:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    return orientation;
}

@end
