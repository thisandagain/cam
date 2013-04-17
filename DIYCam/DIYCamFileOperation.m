//
//  DIYCamFileOperation.m
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamFileOperation.h"

@implementation DIYCamFileOperation

@synthesize complete    = _complete;
@synthesize size        = _size;
@synthesize path        = _path;
@synthesize error       = _error;

#pragma mark - Init

- (id)initWithData:(id)data forLocation:(DIYCamFileLocation)location
{
    self = [super init];
    if (!self) return nil;
    
    dataset     = data;
    _size       = [dataset length];
    _complete   = false;
    
    _path       = [[NSURL alloc] init];
    self.path   = [DIYCamFileOperation generatePathForLocation:location];
    
    _error      = [[NSError alloc] init];
    self.error  = NULL;
    
    return self;
}

#pragma mark - Override

- (void)main
{
    @autoreleasepool {
        NSError *error;
        self.complete = [dataset writeToURL:self.path options:NSDataWritingAtomic error:&error];
        if (error) {
            self.error = error;
        }
    }
}

#pragma mark - Private methods

+ (NSURL *)generatePathForLocation:(DIYCamFileLocation)location
{
    NSArray *paths          = nil;
    NSString *directory     = nil;
    
    switch (location) {
        case DIYCamFileLocationCache:
            paths           = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            directory       = [paths objectAtIndex:0];
            break;
        case DIYCamFileLocationDocuments:
            paths           = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            directory       = [paths objectAtIndex:0];
            break;
        case DIYCamFileLocationTemp:
            directory       = NSTemporaryDirectory();
            break;
    }
    
    NSString *assetName     = [NSString stringWithFormat:@"%@.jpg", [[NSProcessInfo processInfo] globallyUniqueString]];
    NSString *assetPath     = [directory stringByAppendingPathComponent:assetName];
    
    return [NSURL fileURLWithPath:assetPath];
}

#pragma mark - Dealloc

- (void)dealloc
{
    dataset = nil;
}

@end