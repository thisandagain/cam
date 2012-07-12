//
//  DIYCamUtilities.h
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVCaptureConnection;

@interface DIYCamUtilities : NSObject {
    
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;

@end