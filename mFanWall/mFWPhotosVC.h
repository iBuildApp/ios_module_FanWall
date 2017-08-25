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

#import "NRGridViewController.h"
#import "mFWSettings.h"

#import <MWPhotoBrowser/MWPhotoBrowser.h>

/**
 * Controller - list of photos on the wall.
 */
@interface mFWPhotosViewController : UIViewController <NRGridViewDelegate,
                                                       NRGridViewDataSource,
                                                       MWPhotoBrowserDelegate>

/**
 * Container for module essential data.
 */
@property(nonatomic, weak) mFWSettings *fwSettings;

/**
 * Connection helper object.
 */
@property(nonatomic, weak) mFWConnection *FWConnection;

/**
 *  Defines TabBar behavior
 */
@property (nonatomic, assign) BOOL tabBarIsHidden;

/**
 *  Option for show or hide TabBar
 */
@property (nonatomic, assign) BOOL showTabBar;

@end
