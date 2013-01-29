//
//  DIYCamPreview.h
//  cam
//
//  Created by Andrew Sliwinski on 7/7/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface DIYAVPreview : AVCaptureVideoPreviewLayer

@property BOOL                      shouldForceOrientation;
@property AVCaptureVideoOrientation defaultOrientation;

- (void)reset;

@end
