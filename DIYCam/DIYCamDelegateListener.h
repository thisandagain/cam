//
//  DIYCamDelegateListener.h
//  cam
//
//  Created by Andrew Sliwinski on 7/12/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^EmptyBlockType)();

@interface DIYCamDelegateListener : NSObject <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, retain) EmptyBlockType start;
@property (nonatomic, retain) EmptyBlockType end;

+ (void)yesNoWithTitle:(NSString*)title message:(NSString*)message startBlock:(EmptyBlockType)startBlock endBlock:(EmptyBlockType)endBlock;

@end
