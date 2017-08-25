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
 * Delegate which responds to actions of retreiving an image or cancellation of picking.
 */
@protocol mFWImageConsumer <NSObject>

@optional
/**
 * Called when user cancels image picking
 */
- (void) imagePickCancelledCallback;

@required
/**
 * Called when user successfully picks an image
 *
 * @param image - picked image.
 */
- (void) imagePickedCallback:(UIImage *)image;

@end
