# DIYCam

DIYCam is a high-level layer built on top of AVFoundation that enables simple setup and implementation of photo and video capture within iOS. It is pretty darn opinionated though... if you are looking for lots of configuration options then this is probably not the best way to go. If you are looking for something simple but hopefully not "too" simple then read on:

## Getting Started
```objective-c
// Camera
cam = [[DIYCam alloc] init];
[[self cam] setDelegate:self];

// Preview
AVCaptureVideoPreviewLayer *pl = [AVCaptureVideoPreviewLayer layerWithSession:[[self cam] session]];
pl.frame = self.view.frame;
[self.view.layer insertSublayer:pl below:[[self.view.layer sublayers] objectAtIndex:0]];

// Gravity
CGRect bounds   = self.view.layer.bounds;
pl.videoGravity = AVLayerVideoGravityResizeAspectFill;
pl.bounds       = bounds;
pl.position     = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
```

## Public Methods
```objective-c
- (void)startPhotoCapture;
- (void)startVideoCapture;
- (void)stopVideoCapture;
- (bool)isRecording;
```