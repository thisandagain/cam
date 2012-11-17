//
//  DIYCamLibraryVideoOperation.m
//  cam
//
//  Created by Jonathan Beilin on 7/18/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamLibraryVideoOperation.h"

@implementation DIYCamLibraryVideoOperation

@synthesize complete = _complete;
@synthesize path = _path;
@synthesize error = _error;

#pragma mark - Init

- (id)initWithURL:(id)videoURL
{
    self = [super init];
    if (!self) return nil;
    
    _complete = false;
    self.path = videoURL;
    _error = [[NSError alloc] init];
    self.error = NULL;
    
    return self;
}

#pragma mark - Override

- (void)main
{
    @try {        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];
        
        [library writeVideoAtPathToSavedPhotosAlbum:self.path completionBlock:^(NSURL *assetURL, NSError *error) {
            self.error = error;
            self.complete = true;
        }];
        
        [pool release];
    }
    @catch (NSException *exception) { }
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [_path release]; _path = nil;
    [_error release]; _error = nil;
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end
