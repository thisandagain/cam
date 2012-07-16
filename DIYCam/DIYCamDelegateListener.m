//
//  DIYCamDelegateListener.m
//  cam
//
//  Created by Andrew Sliwinski on 7/12/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamDelegateListener.h"

@implementation DIYCamDelegateListener

@synthesize start = _start;
@synthesize end = _end;

#pragma mark - Init

- (id)initWithStartBlock:(EmptyBlockType)startBlock endBlock:(EmptyBlockType)endBlock
{
    self = [super init];
    if (self)
    {
        self.start  = [[_start copy] autorelease];
        self.end    = [[_end copy] autorelease];
    }
    return self;
}

#pragma mark - Delegation

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    self.start();
    
    [_start release];
    [captureOutput release];
    [self release];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    self.end();
    
    [_end release];
    [captureOutput release];
    [self release];
}

#pragma mark - Public methods

+ (void)startRecordingToOutputFileURL:(NSURL *)url start:(EmptyBlockType)start
{
    
}

+ (void)stopRecording:(EmptyBlockType)end
{
    
}

/*
+ (void)yesNoWithTitle:(NSString*)title message:(NSString*)message yesBlock:(EmptyBlockType)yesBlock noBlock:(EmptyBlockType)noBlock
{
    YUYesNoListener* yesNoListener = [[YUYesNoListener alloc] initWithYesBlock:yesBlock noBlock:noBlock];
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:yesNoListener cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] show];
}
 */

@end
