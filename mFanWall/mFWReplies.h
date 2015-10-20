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

#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "EGORefreshTableHeaderView.h"
#import "mFWInputToolbar.h"

/**
 *  Detail ViewController for comment with list of replies in widget FanWall
 */
@interface mFWReplies : UIViewController <UITableViewDataSource,
                                          UITableViewDelegate,
                                          UIGestureRecognizerDelegate,
                                          mFWConnectionDelegate,
                                          MWPhotoBrowserDelegate,
                                          EGORefreshTableHeaderDelegate,
                                          mFWInputToolbarDelegate>

/**
 *  Parent message ID.
 */
@property (nonatomic, copy  ) NSString             *r1parentID;

/**
 *  Reply ID.
 */
@property (nonatomic, copy  ) NSString             *r1replyID;

/**
 *  First post dictionary.
 */
@property (nonatomic, copy  ) NSMutableDictionary  *r1firstPost;

/**
 *  Array of photos.
 */
@property (nonatomic, strong) NSMutableArray              *photos;

/**
 * Tells whether we went here from wall or from second level of comments or new comment screen.
 */
@property(nonatomic, assign) BOOL firstTimeLoad;

@end
