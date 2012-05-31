# DIYCam

DIYCam is a high-level layer built on top of AVFoundation that enables simple setup and implementation of photo and video capture within iOS. It is pretty darn opinionated though... if you are looking for lots of configuration options then this is probably not the best way to go. If you are looking for something simple but hopefully not "too" simple then read on:

## Getting Started
```objective-c
// Init camera
cam = [[DIYCam alloc] init];
[[self cam] setDelegate:self];
[[self cam] setup];

// Preview
cam.preview.frame       = display.frame;
[display.layer addSublayer:cam.preview];

CGRect bounds           = display.layer.bounds;
cam.preview.bounds      = bounds;
cam.preview.position    = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
```

## Public Methods
```objective-c
- (void)setup;
- (void)startPhotoCapture;
- (void)startVideoCapture;
- (void)stopVideoCapture;
- (bool)isRecording;
```

## Delegate Methods
```objective-c
- (void)camReady:(DIYCam *)cam;
- (void)camDidFail:(DIYCam *)cam withError:(NSError *)error;
- (void)camCaptureStarted:(DIYCam *)cam;
- (void)camCaptureStopped:(DIYCam *)cam;
- (void)camCaptureProcessing:(DIYCam *)cam;
- (void)camCaptureComplete:(DIYCam *)cam withAsset:(NSDictionary *)asset;
```