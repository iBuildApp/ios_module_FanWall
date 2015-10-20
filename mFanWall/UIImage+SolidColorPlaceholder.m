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

#import "UIImage+SolidColorPlaceholder.h"

@implementation UIImage (SolidColorPlaceholder)

+ (UIImage *)placeholderWithSize:(CGSize)size
                        andColor:(UIColor *)color {
  
  CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
  
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
  
  return image;
}

@end
