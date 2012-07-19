//
//  DIYCamUtilities.m
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamUtilities.h"

@implementation DIYCamUtilities

#pragma mark - General

+ (AVCaptureDevice *)camera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
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
            [[DIYCamUtilities camera] unlockForConfiguration];
        }
    }
}

#pragma mark - Path helpers
+ (NSString *)createAssetFilePath:(NSString *)extension
{
    NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory    = [paths objectAtIndex:0];
    NSString *assetName             = [NSString stringWithFormat:@"%@.%@", [[NSProcessInfo processInfo] globallyUniqueString], extension];
    NSString *assetPath             = [documentsDirectory stringByAppendingPathComponent:assetName];
    
    return assetPath;
}


@end
