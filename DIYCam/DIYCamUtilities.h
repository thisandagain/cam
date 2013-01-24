//
//  DIYCamUtilities.h
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class DIYCamPreview;

@interface DIYCamUtilities : NSObject

+ (NSString *)createAssetFilePath:(NSString *)extension;
+ (void)generateVideoThumbnail:(NSURL *)url success:(void (^)(UIImage *image, NSData *data))success failure:(void (^)(NSException *exception))failure;

@end
