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
 * Controller to show FanWall messages near you.
 */
@interface mFWMap : UIViewController <CLLocationManagerDelegate, UIWebViewDelegate>

/**
 * Points to be displayed on map.
 */
@property (nonatomic, strong) NSMutableArray *mapPoints;

/**
 *  Defines TabBar behavior.
 */
@property (nonatomic, assign) BOOL tabBarIsHidden;

/**
 *  Option for show or hide TabBar.
 */
@property (nonatomic, assign) BOOL showTabBar;

/**
 * Reloads map.
 */
- (void)reload;

@end