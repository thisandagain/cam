//
//  DIYCamThumbnailOperation.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamThumbnailOperation.h"

@implementation DIYCamThumbnailOperation

/*
- (void)generateVideoThumbnail:(NSString*)url success:(void (^)(UIImage *image, NSURL *path))success failure:(void (^)(NSException *exception))failure
{
    // Setup
    AVURLAsset *asset                   = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:url] options:nil];
    Float64 durationSeconds             = CMTimeGetSeconds([asset duration]);
    CMTime thumbTime                    = CMTimeMakeWithSeconds(durationSeconds / 2.0, 600);
    
    // Generate
    self.thumbnailGenerator             = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    thumbnailGenerator.maximumSize      = CGSizeMake(VIDEO_THUMB_WIDTH, VIDEO_THUMB_HEIGHT);
    [thumbnailGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
        NSString *requestedTimeString = (NSString *)CMTimeCopyDescription(NULL, requestedTime);
        NSString *actualTimeString = (NSString *)CMTimeCopyDescription(NULL, actualTime);
        NSLog(@"Requested: %@; actual %@", requestedTimeString, actualTimeString);
        [requestedTimeString release];
        [actualTimeString release];
        
        //
        
        if (result != AVAssetImageGeneratorSucceeded) 
        {
            failure([NSException exceptionWithName:@"" reason:@"Could not generate video thumbnail" userInfo:nil]);
        } else {
            UIImage *sim = [UIImage imageWithCGImage:im];
            success(sim, [sim saveToCache]);
        }
        
        [asset release];
    }];
}
 */

@end
