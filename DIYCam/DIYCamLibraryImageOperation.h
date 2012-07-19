//
//  DIYCamLibraryImageOperation.h
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface DIYCamLibraryImageOperation : NSOperation
{
    id dataset;
}

@property (atomic, assign) BOOL complete;
@property (atomic, assign) NSUInteger size;
@property (atomic, retain) NSURL *path;
@property (atomic, retain) NSError *error;

- (id)initWithData:(id)data;

@end
