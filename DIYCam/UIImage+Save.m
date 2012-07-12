//
//  UIImage+Save.m
//  DIYCam
//
//  Created by Andrew Sliwinski on 6/21/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "UIImage+Save.h"

@implementation UIImage (Save)

#pragma mark - Public methods

- (NSURL *)saveToTemporary
{
    NSData *imageData       = UIImageJPEGRepresentation(self, 0.9);
    NSString *assetPath     = [self createAssetFilePath:0 withExtension:@"jpg"];
    [imageData writeToFile:assetPath atomically:true];
    
    return [NSURL URLWithString:assetPath];
}

- (NSURL *)saveToCache
{
    NSData *imageData       = UIImageJPEGRepresentation(self, 0.9);
    NSString *assetPath     = [self createAssetFilePath:1 withExtension:@"jpg"];
    [imageData writeToFile:assetPath atomically:true];
    
    return [NSURL URLWithString:assetPath];
}

#pragma mark - Private methods

- (NSString *)createAssetFilePath:(int)type withExtension:(NSString *)extension
{
    NSArray *paths                  = nil;
    NSString *documentsDirectory    = nil;
    
    switch (type) {
        case 0:
            documentsDirectory      = NSTemporaryDirectory();
            break;
        default:
            paths                   = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            documentsDirectory      = [paths objectAtIndex:0];
            break;
    }
    
    NSString *assetName             = [NSString stringWithFormat:@"%@.%@", [[NSProcessInfo processInfo] globallyUniqueString], extension];
    NSString *assetPath             = [documentsDirectory stringByAppendingPathComponent:assetName];
    
    return assetPath;
}

@end
