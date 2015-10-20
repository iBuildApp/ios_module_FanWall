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
#import <UIKit/UIKit.h>
#import "NRGridViewController.h"

#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <auth_Share/auth_Share.h>

#import "EGORefreshTableHeaderView.h"
#import "mFWInputToolbar.h"
#import "mFWImageConsumer.h"

/**
 *  Main module class for widget FanWall. Module entry point.
 */
@interface mFanWallViewController : UIViewController <UITableViewDataSource,
                                                      UITableViewDelegate,
                                                      UIActionSheetDelegate,
                                                      UIGestureRecognizerDelegate,
                                                      CLLocationManagerDelegate,

                                                      NRGridViewDelegate,
                                                      NRGridViewDataSource,
                                                      MWPhotoBrowserDelegate,
                                                      EGORefreshTableHeaderDelegate,
                                                      mFWInputToolbarDelegate,
                                                      auth_ShareDelegate>

/**
 *  Array of parsed widget data
 */
@property(nonatomic, copy  ) NSArray  *array;

/**
 *  Application ID
 */
@property(nonatomic, copy  ) NSString *appID;

@property (nonatomic, retain) UIImage *screenshotImage;

@end