//
//  DIYCamRecorder.m
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamRecorder.h"

@interface DIYCamRecorder (FileOutputDelegate) <AVCaptureFileOutputRecordingDelegate>
@end

@implementation DIYCamRecorder

@synthesize session;
@synthesize movieFileOutput;
@synthesize outputFileURL;
@synthesize delegate;

#pragma mark - Init

- (id)initWithSession:(AVCaptureSession *)aSession outputFileURL:(NSURL *)anOutputFileURL
{
    self = [super init];
    if (self != nil) {
        AVCaptureMovieFileOutput *aMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([aSession canAddOutput:aMovieFileOutput])
            [aSession addOutput:aMovieFileOutput];
        [self setMovieFileOutput:aMovieFileOutput];
        [aMovieFileOutput release];
		
		[self setSession:aSession];
		[self setOutputFileURL:anOutputFileURL];
    }
    
	return self;
}

- (BOOL)recordsVideo
{
	AVCaptureConnection *videoConnection = [DIYCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self movieFileOutput] connections]];
    NSLog(@"VID!: %@", videoConnection);
	return [videoConnection isActive];
}

- (BOOL)recordsAudio
{
	AVCaptureConnection *audioConnection = [DIYCamUtilities connectionWithMediaType:AVMediaTypeAudio fromConnections:[[self movieFileOutput] connections]];
	return [audioConnection isActive];
}

- (BOOL)isRecording
{
    return [[self movieFileOutput] isRecording];
}

- (void)startRecordingWithOrientation:(AVCaptureVideoOrientation)videoOrientation;
{
    NSLog(@"Video: %d", [self recordsVideo]);
    AVCaptureConnection *videoConnection = [DIYCamUtilities connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self movieFileOutput] connections]];
    NSLog(@"Connection: %@", videoConnection);
    if ([videoConnection isVideoOrientationSupported])
    {
        [videoConnection setVideoOrientation:videoOrientation];
    }
    
    NSLog(@"Movie File Output: %@", [self movieFileOutput]);
    NSLog(@"Output: %@", [self outputFileURL]);
    
    [[self movieFileOutput] startRecordingToOutputFileURL:[self outputFileURL] recordingDelegate:self];
}

- (void)stopRecording
{
    [[self movieFileOutput] stopRecording];
}

@end

@implementation DIYCamRecorder (FileOutputDelegate)

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    if ([[self delegate] respondsToSelector:@selector(recorderRecordingDidBegin:)]) 
    {
        [[self delegate] recorderRecordingDidBegin:self];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)anOutputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if ([[self delegate] respondsToSelector:@selector(recorder:recordingDidFinishToOutputFileURL:error:)]) 
    {
        [[self delegate] recorder:self recordingDidFinishToOutputFileURL:anOutputFileURL error:error];
    }
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [[self session] removeOutput:[self movieFileOutput]];
	[session release];
	[outputFileURL release];
	[movieFileOutput release];
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end