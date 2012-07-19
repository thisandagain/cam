//
//  DIYCamUtilities.h
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface DIYCamUtilities : NSObject

+ (AVCaptureDevice *)camera;
+ (BOOL)isPhotoCameraAvailable;
+ (BOOL)isVideoCameraAvailable;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

+ (void)setFlash:(BOOL)flash;

+ (NSString *)createAssetFilePath:(NSString *)extension;
+ (void)generateVideoThumbnail:(NSURL *)url success:(void (^)(UIImage *image, NSData *data))success failure:(void (^)(NSException *exception))failure;

@end
