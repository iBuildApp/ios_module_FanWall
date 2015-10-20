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

#import <UIKit/UIKit.h>

/**
 * Category on UIImage to generate image from color.
 */
@interface UIImage (SolidColorPlaceholder)

/**
 * Generates image of specified size and color
 *
 * @param 
 */
+ (UIImage *)placeholderWithSize:(CGSize)size
                        andColor:(UIColor *)color;
@end
