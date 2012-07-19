//
//  DIYCamLibraryVideoOperation.h
//  cam
//
//  Created by Jonathan Beilin on 7/18/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface DIYCamLibraryVideoOperation : NSOperation

@property (atomic, assign) BOOL complete;
@property (atomic, retain) NSURL *path;
@property (atomic, retain) NSError *error;

- (id)initWithURL:(id)videoURL;

@end
