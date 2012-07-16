//
//  DIYCamLibraryOperation.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamLibraryOperation.h"

@implementation DIYCamLibraryOperation

@synthesize complete = _complete;
@synthesize size = _size;
@synthesize path = _path;
@synthesize error = _error;

#pragma mark - Init

- (id)initWithData:(id)data
{
    if (![super init]) return nil;
    
    dataset     = [data retain];
    _size       = [dataset length];
    _complete   = false;
    _path       = [[NSURL alloc] init];
    _error      = [[NSError alloc] init];
    self.error  = NULL;
    
    return self;
}

#pragma mark - Override

- (void)main
{
    @try 
    {        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];
        [library writeImageDataToSavedPhotosAlbum:dataset metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            self.path = assetURL;
            self.error = error;
            self.complete = true;
        }];
        [pool release];
    } @catch (NSException *exception) {
        [exception raise];
    }
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [dataset release]; dataset = nil;
    [_path release]; _path = nil;
    [_error release]; _error = nil;
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end