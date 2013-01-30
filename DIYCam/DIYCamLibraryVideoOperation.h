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

@property BOOL              complete;
@property NSURL             *path;
@property NSError           *error;
@property ALAssetsLibrary   *library;

- (id)initWithURL:(id)videoURL;

@end
