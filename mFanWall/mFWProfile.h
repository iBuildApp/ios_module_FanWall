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
 *  ViewController for displaying user profile
 */
@interface mFWProfile : UIViewController <mFWConnectionDelegate>

/**
 *  Avatar image URL string
 */
@property (nonatomic, copy) NSString *avatarURL;

/**
 *  User name
 */
@property (nonatomic, copy) NSString *userName;

/**
 *  Account ID
 */
@property (nonatomic, copy) NSString *accountID;

/**
 *  Account type
 */
@property (nonatomic, copy) NSString *accountType;

/**
 *  String representation of date
 */
@property (nonatomic, copy) NSString *dateString;

/**
 *  Number of posts (string representation)
 */
@property (nonatomic, copy) NSString *pCountText;

/**
 *  Number of comments (string representation)
 */
@property (nonatomic, copy) NSString *cCountText;

@end