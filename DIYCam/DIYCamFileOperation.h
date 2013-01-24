//
//  DIYCamFileOperation.h
//  cam
//
//  Created by Andrew Sliwinski on 7/5/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import <Foundation/Foundation.h>

//

typedef enum {
    DIYCamFileLocationCache,
    DIYCamFileLocationDocuments,
    DIYCamFileLocationTemp
} DIYCamFileLocation;

@interface DIYCamFileOperation : NSOperation
{
    id dataset;
}

@property BOOL          complete;
@property NSUInteger    size;
@property NSURL         *path;
@property NSError       *error;

- (id)initWithData:(id)data forLocation:(DIYCamFileLocation)location;
+ (NSURL *)generatePathForLocation:(DIYCamFileLocation)location;

@end
