/****************************************************************************
 *                                                                           *
 *  Copyright (C) 2014-2015 iBuildApp, Inc. ( http://ibuildapp.com )         *
 *                                                                           *
 *  This file is part of iBuildApp.                                          *
 *                                                                           *
 *  This Source Code Form is subject to the terms of the iBuildApp License.  *
 *  You can obtain one at http://ibuildapp.com/license/                      *
 *                                                                           *
 ****************************************************************************/

#import <Foundation/Foundation.h>

/**
 * Container class for module's essential data.
 */
@interface mFWSettings : NSObject

/**
 *  Array of image links.
 */
@property(nonatomic, strong) NSMutableArray *imageLinks;

/**
 *  Array of photos.
 */
@property(nonatomic, strong) NSArray  *photos;

/**
 *  Array of posts.
 */
@property(nonatomic, strong) NSMutableArray *posts;

/**
 *  Array of images.
 */
@property(nonatomic, strong) NSMutableArray *images;

/**
 *  Method for formatting post creation date as a sentence describing the time from now.
 */
+ (NSString *) dateDiffForDate:(NSDate*)date;

@end
