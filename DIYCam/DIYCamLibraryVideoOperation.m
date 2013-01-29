//
//  DIYCamLibraryVideoOperation.m
//  cam
//
//  Created by Jonathan Beilin on 7/18/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamLibraryVideoOperation.h"

@implementation DIYCamLibraryVideoOperation

#pragma mark - Init

- (id)initWithURL:(id)videoURL
{
    self = [super init];
    if (!self) return nil;
    
    _complete = false;
    self.path = videoURL;
    _error = [[NSError alloc] init];
    self.error = NULL;
    _library = [[ALAssetsLibrary alloc] init];
    
    return self;
}

#pragma mark - Override

- (void)main
{
    @try {
        @autoreleasepool {            
            [self.library writeVideoAtPathToSavedPhotosAlbum:self.path completionBlock:^(NSURL *assetURL, NSError *error) {
                self.error = error;
                self.complete = true;
            }];
        }
    }
    @catch (NSException *exception) {
    }
}

@end
