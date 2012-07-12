//
//  UIImage+Save.h
//  DIYCam
//
//  Created by Andrew Sliwinski on 6/21/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

@interface UIImage (Save)

- (NSURL *)saveToTemporary;
- (NSURL *)saveToCache;

@end