//
//  DIYCamScaler.m
//  DIYCam
//
//  Created by Andrew Sliwinski on 5/29/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "DIYCamScaler.h"

@implementation DIYCamScaler

- (UIImage *)makeImageOfSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (newThumbnail == nil) 
    {
        NSLog(@"Could not scale image"); 
        return self;
    } else {
        return newThumbnail;
    }
}

@end