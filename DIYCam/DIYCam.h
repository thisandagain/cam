//
//  DIYCam.h
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "DIYCamDefaults.h"
#import "DIYCamPreview.h"
#import "DIYCamUtilities.h"
#import "DIYCamFileOperation.h"
#import "DIYCamLibraryOperation.h"
#import "DIYCamThumbnailOperation.h"

//

typedef enum {
    DIYCamModePhoto,
    DIYCamModeVideo
} DIYCamMode;

@class DIYCam;

@protocol DIYCamDelegate <NSObject>
@required
- (void)camReady:(DIYCam *)cam;
- (void)camDidFail:(DIYCam *)cam withError:(NSError *)error;

- (void)camModeWillChange:(DIYCam *)cam mode:(DIYCamMode)mode;
- (void)camModeDidChange:(DIYCam *)cam mode:(DIYCamMode)mode;
@end

//

@interface DIYCam : UIView

@property (nonatomic, assign) id<DIYCamDelegate> delegate;
@property (nonatomic, assign) DIYCamMode captureMode;
@property (nonatomic, retain) AVCaptureSession *session;

- (void)capturePhoto:(void (^)(NSDictionary *asset))success failure:(void (^)(NSError *error))failure;
- (void)captureVideoStart;
- (void)captureVideoEnd:(void (^)(NSDictionary *asset))success failure:(void (^)(NSError *error))failure;

@end