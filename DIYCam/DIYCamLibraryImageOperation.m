//
//  DIYCamLibraryImageOperation.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamLibraryImageOperation.h"

@implementation DIYCamLibraryImageOperation

@synthesize complete    = _complete;
@synthesize size        = _size;
@synthesize path        = _path;
@synthesize error       = _error;
@synthesize library     = _library;

#pragma mark - Init

- (id)initWithData:(id)data
{
    self = [super init];
    if (!self) return nil;
    
    dataset     = data;
    _size       = [dataset length];
    _complete   = false;
    _path       = [[NSURL alloc] init];
    _error      = [[NSError alloc] init];
    _library    = [[ALAssetsLibrary alloc] init];
    self.error  = NULL;
    
    return self;
}

#pragma mark - Override

- (void)main
{
    @autoreleasepool {
        [self.library writeImageDataToSavedPhotosAlbum:dataset metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            self.path = assetURL;
            self.error = error;
            self.complete = true;
        }];
    }
}

#pragma mark - Dealloc

- (void)dealloc
{
    dataset = nil;
}

@end