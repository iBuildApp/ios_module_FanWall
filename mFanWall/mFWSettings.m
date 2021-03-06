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

#import "mFWSettings.h"
#import "functionLibrary.h"

@implementation mFWSettings

#pragma mark - NSObject
- (id) init
{
  self = [super init];
  
  _imageLinks = [[NSMutableArray alloc] init];
  _photos = nil;
  
  return self;
  
}



+ (NSString *) dateDiffForDate:(NSDate*)date
{
  return [functionLibrary formatTimeInterval:date];
}



@end
