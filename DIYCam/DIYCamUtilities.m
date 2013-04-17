//
//  DIYCamUtilities.m
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamUtilities.h"

@implementation DIYCamUtilities

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
    __block AVAssetImageGenerator *thumbnailGenerator   = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    thumbnailGenerator.maximumSize              = CGSizeMake(1280, 720);
    [thumbnailGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        thumbnailGenerator = nil;
        
        if (result != AVAssetImageGeneratorSucceeded) {
            failure([NSException exceptionWithName:@"" reason:@"Could not generate video thumbnail" userInfo:nil]);
        } else {
            UIImage *sim = [UIImage imageWithCGImage:im];
            NSData *data = UIImageJPEGRepresentation(sim, 0.7f);
            success(sim, data);
        }
    }];
}

@end
