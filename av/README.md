## AV
#### A "keep it simple, stupid" approach to working with AVFoundation

DIYAV is a high-level layer built on top of AVFoundation that enables simple setup and implementation of photo and video capture within iOS.

## Getting Started
The easiest way to get going with DIYAV is to take a look at DIYCam.

In order to use DIYAV, you'll want to add the entirety of the `DIYAV` directory to your project. To get started, simply:

```objective-c
#import "DIYAV.h"
```

```objective-c
DIYAV *diyAV         = [[DIYAV alloc] init];
diyAV.delegate        = self;
```

You'll also need to link the following frameworks:

```bash
AssetsLibrary.framework
AVFoundation.framework
CoreGraphics.framework
CoreMedia.framework
MobileCoreServices.framework
QuartzCore.framework
```

## Configuration
Default configuration settings can be modified within DIYCamDefaults.h where options for asset library use, orientation, device settings, and quality can be modified.

---

## Methods
```objective-c
- (id)initWithOptions:(NSDictionary *)options;

- (void)startSession;
- (void)stopSession;
- (void)focusAtPoint:(CGPoint)point inFrame:(CGRect)frame;
- (void)capturePhoto;
- (void)captureVideoStart;
- (void)captureVideoStop;
```

## Delegate Methods
```objective-c
- (void)AVAttachPreviewLayer:(CALayer *)layer;

- (void)AVDidFail:(DIYAV *)av withError:(NSError *)error;

- (void)AVModeWillChange:(DIYAV *)av mode:(DIYAVMode)mode;
- (void)AVModeDidChange:(DIYAV *)av mode:(DIYAVMode)mode;

- (void)AVCaptureStarted:(DIYAV *)av;
- (void)AVCaptureStopped:(DIYAV *)av;
- (void)AVcaptureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error;
- (void)AVCaptureOutputStill:(CMSampleBufferRef)imageDataSampleBuffer withError:(NSError *)error;
```

## Properties
```objective-c
@property (weak)        id<DIYAVDelegate>   delegate;
@property (nonatomic)   DIYAVMode           captureMode;
@property               BOOL                isRecording;
```

---

## iOS Support
DIYAV is tested on iOS 5 and up. Older versions of iOS may work but are not currently supported.

## ARC
DIYAV uses ARC. If you are including DIYAV in a project that **does not** use [Automatic Reference Counting (ARC)](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html), you will need to set the `-fobjc-arc` compiler flag on all of the DIYAV source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all DIYAV source files, press Enter, insert `-fobjc-arc` and then "Done" to enable ARC for DIYAV.
