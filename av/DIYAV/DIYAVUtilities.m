//
//  DIYAVUtilities.m
//  DIYAV
//
//  Created by Jonathan Beilin on 1/22/13.
//  Copyright (c) 2013 DIY. All rights reserved.
//

#import "DIYAVUtilities.h"

#import "DIYAVDefaults.h"
#import "DIYAVPreview.h"

#import <MobileCoreServices/UTCoreTypes.h>

@implementation DIYAVUtilities

#pragma mark - General

+ (AVCaptureDevice *)cameraInPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
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

+ (void)setFlash:(BOOL)flash forCameraInPosition:(AVCaptureDevicePosition)position
{
    // Flash
    if ([[self cameraInPosition:position] hasFlash]) {
        if ([[self cameraInPosition:position] lockForConfiguration:nil]) {
            if (flash) {
                if ([[self cameraInPosition:position] isFlashModeSupported:AVCaptureFlashModeAuto]) {
                    [[self cameraInPosition:position] setFlashMode:AVCaptureFlashModeAuto];
                }
            } else {
                if ([[self cameraInPosition:position] isFlashModeSupported:AVCaptureFlashModeOff]) {
                    [[self cameraInPosition:position] setFlashMode:AVCaptureFlashModeOff];
                }
            }
            [[self cameraInPosition:position] unlockForConfiguration];
        }
    }
    
    // Torch
    if ([[self cameraInPosition:position] hasTorch]) {
        if ([[self cameraInPosition:position] lockForConfiguration:nil]) {
            if (flash)
            {
                if ([[self cameraInPosition:position] isTorchModeSupported:AVCaptureTorchModeAuto]) {
                    [[self cameraInPosition:position] setTorchMode:AVCaptureTorchModeAuto];
                }
            } else {
                if ([[self cameraInPosition:position] isTorchModeSupported:AVCaptureTorchModeOff]) {
                    [[self cameraInPosition:position] setTorchMode:AVCaptureTorchModeOff];
                }
            }
            [[self cameraInPosition:position] unlockForConfiguration];
        }
    }
}

+ (void)setHighISO:(BOOL)highISO forCameraInPosition:(AVCaptureDevicePosition)position
{
    if ([[self cameraInPosition:position] respondsToSelector:@selector(isLowLightBoostSupported)]) {
        if ([[self cameraInPosition:position] lockForConfiguration:nil] && [self cameraInPosition:position].isLowLightBoostSupported) {
            [self cameraInPosition:position].automaticallyEnablesLowLightBoostWhenAvailable = highISO;
            [[self cameraInPosition:position] unlockForConfiguration];
        }
    }
}

#pragma mark - Utility methods

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
+ (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates withFrame:(CGRect)frame withPreview:(DIYAVPreview *)preview withPorts:(NSArray *)ports
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = frame.size;
    
    if (preview.isMirrored) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ([preview.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in ports) {
            if (port.mediaType == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ([preview.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([preview.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    CGPoint correctedPoint = CGPointMake(1.0f - pointOfInterest.y, pointOfInterest.x);
    return correctedPoint;
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

#pragma mark - Asset helpers

+ (NSString *)createAssetFilePath:(NSString *)extension
{
    NSArray *paths                  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory    = [paths objectAtIndex:0];
    NSString *assetName             = [NSString stringWithFormat:@"%@.%@", [[NSProcessInfo processInfo] globallyUniqueString], extension];
    NSString *assetPath             = [documentsDirectory stringByAppendingPathComponent:assetName];
    
    return assetPath;
}

@end
