//
//  DIYCamDefaults.h
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

/**
 * Device settings
 */
#define DEVICE_FLASH                false
#define DEVICE_DISK_MINIMUM         49999872
#define DEVICE_ORIENTATION_FORCE    false
#define DEVICE_ORIENTATION_DEFAULT  AVCaptureVideoOrientationLandscapeRight
#define DEVICE_POSITION             AVCaptureDevicePositionBack
#define DEVICE_HI_ISO               true

/**
 * Photo settings
 */
#define PHOTO_SESSION_PRESET        AVCaptureSessionPresetPhoto
#define PHOTO_SESSION_GRAVITY       AVLayerVideoGravityResizeAspectFill

/**
 * Video settings
 */
#define VIDEO_SESSION_PRESET        AVCaptureSessionPreset1280x720
#define VIDEO_SESSION_GRAVITY       AVLayerVideoGravityResizeAspectFill
#define VIDEO_MAX_DURATION          300
#define VIDEO_FPS                   30

/**
 * File I/O settings
 */
#define SAVE_ASSET_LIBRARY          true

/**
 * Output buffer settings
 */
#define OUTPUT_BUFFER               true
#define OUTPUT_BUFFER_DISCARD       true
#define OUTPUT_BUFFER_SETTINGS      @{}
