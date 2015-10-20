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
#import "mFWExpandingTextViewInternal.h"
#import "inputToolbar/expandingTextView.h"
#import "mFWInputToolbar.h"

@class mFWInputToolbar;

/**
 * Customized text view, expands while typing message (if needed).
 */
@interface mFWExpandingTextView : expandingTextView

/**
 * Owning mFWInputToolbar.
 */
@property (nonatomic, strong) mFWInputToolbar *owner;

@end
