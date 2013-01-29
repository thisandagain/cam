## Cam
#### A turn-key camera capture solution built on top of DIYAV (on top of AVFoundation), enabling simple setup and implementation of photo and video capture within iOS.

## Getting Started
The easiest way to get going with DIYCam is to take a look at the included example application. The XCode project file can be found at `Example > cam.xcodeproj`.

In order to use DIYCam, you'll want to add the entirety of the `DIYCam` directory to your project. To get started, simply:

```objective-c
#import "DIYCam.h"
```

```objective-c
DIYCam *cam         = [[DIYCam alloc] initWithFrame:self.view.frame];
cam.delegate        = self;
[cam setupWithOptions:nil]; // Check DIYAV.h for options
[cam setCamMode:DIYAVModePhoto];
[self.view addSubview:cam];
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
#pragma mark - Status
- (BOOL)getRecordingStatus;
- (DIYAVMode)getCamMode;
- (void)setCamMode:(DIYAVMode)mode;

#pragma mark - Capture
- (void)stopSession;
- (void)startSession;

- (void)capturePhoto;
- (void)captureVideoStart;
- (void)captureVideoStop;
```

## Delegate Methods
```objective-c
- (void)camDidFail:(DIYCam *)cam withError:(NSError *)error;

- (void)camModeWillChange:(DIYCam *)cam mode:(DIYAVMode)mode;
- (void)camModeDidChange:(DIYCam *)cam mode:(DIYAVMode)mode;

- (void)camCaptureStarted:(DIYCam *)cam;
- (void)camCaptureStopped:(DIYCam *)cam;
- (void)camCaptureProcessing:(DIYCam *)cam;
- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset;
```

## Properties
```objective-c
@property (nonatomic, assign) id<DIYCamDelegate> delegate;
```

---

## iOS Support
DIYCam is tested on iOS 5 and up. Older versions of iOS may work but are not currently supported.

## ARC
As of v1.1.0 DIYCam uses ARC. If you are including DIYCam in a project that **does not** use [Automatic Reference Counting (ARC)](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html), you will need to set the `-fobjc-arc` compiler flag on all of the DIYCam source files. To do this in Xcode, go to your active target and select the "Build Phases" tab. Now select all DIYCam source files, press Enter, insert `-fobjc-arc` and then "Done" to enable ARC for DIYCam.
