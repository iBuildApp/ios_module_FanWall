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
#import "mFWSocialButton.h"
//
//#define kSpaceBetweenSocialImageAndActionsCount 6.0f
//#define kSocialActionsCountFontSize 14.0f
//
//#define kSocialButtonFrameWithOriginX(originX) (CGRect){originX, 0.0f, kPostCellWidth / 3, kSocialButtonHeight}

/**
 * Control showing an icon for social action (like, share, comment) and
 * count of that actions already performed.
 */
@interface mFWSocialButtonWithoutLikes : UIView

/**
 * Icon for social action (comment, sharing, like).
 */
@property (nonatomic, retain) UIImage *socialImage;

/**
 * ImageView for socialImage, in case you want customization.
 */
@property (nonatomic, retain, readonly) UIImageView *socialImageView;

/**
 * Social actions count, e.g. count of likes.
 */
@property (nonatomic) NSUInteger socialActionsCount;

@end
