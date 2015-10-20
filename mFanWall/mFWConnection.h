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
#import <CoreLocation/CoreLocation.h>
#import "mFWURLLoader.h"
#import "mFWInputToolbar.h"

#define kMessagesNoLimit 2147483647

/**
 *  mFWConnection's marker protocol.
 */
@protocol mFWConnectionDelegate

@end

/**
 *  Singleton for storing module parameters and exchanging data with server
 */
@interface mFWConnection : NSObject <CLLocationManagerDelegate, UIAlertViewDelegate>
{
    BOOL isLoggedIn;
    BOOL isReceivedError;
}

/**
 *  mFWConnection delegate
 */
@property (nonatomic, assign) id<mFWConnectionDelegate, CLLocationManagerDelegate> delegate;

/**
 *  Login status
 */
@property BOOL isLoggedIn;

/**
 *  Indicator of error received
 */
@property BOOL isReceivedError;

/**
 *  Indicator of request finished
 */
@property BOOL finished;

/**
 *  Indicator of login canceled
 */
@property BOOL loginCanceled;

/**
 *  Server response
 */
@property (nonatomic, strong) NSDictionary *serverResponse;

/**
 *  Message from server
 */
@property (nonatomic, strong) NSString     *serverMessage;


/**
 * Application ID
 */
@property (nonatomic, copy  ) NSString *mFWAppID;

/**
 *  Module ID
 */
@property (nonatomic, copy  ) NSString *mFWModuleID;

/**
 *  Allow editing
 */
@property (nonatomic, copy  ) NSString *mFWCanEdit;

/**
 *  Account ID
 */
@property (nonatomic, copy  ) NSString *mFWAccountID;

/**
 *  Account type
 */
@property (nonatomic, copy  ) NSString *mFWAccountType;

/**
 *  User name
 */
@property (nonatomic, copy  ) NSString *mFWUserName;

/**
 *  Avatar URL string
 */
@property (nonatomic, copy  ) NSString *mFWAvatar;

/**
 * Flag being set to <code>YES</code> after submitting a message.
 */
@property BOOL afterPost;

/**
 * @deprecated
 * Flag, was being set to <code>YES</code> after submitting a comment.
 */
@property BOOL afterReply;

/**
 * @deprecated
 * Flag, was being set to <code>YES</code> after submitting a comment to comment.
 */
@property BOOL afterReply2;

/**
 * Flag, telling whether the wall should be refershed.
 */
@property BOOL requiresRequest;

/**
 *  Index of chosen cell
 */
@property (nonatomic, strong) NSIndexPath *activeCell;

/**
 *  Index of active image
 */
@property (nonatomic, strong) NSIndexPath *activeImage;

/**
 *  Background color
 */
@property (nonatomic, retain) UIColor *mFWColorOfBackground;

/**
 *  Color of time label.
 */
@property (nonatomic, retain) UIColor *mFWColorOfWallTime;

/**
 *  Color of text header
 */
@property (nonatomic, retain) UIColor *mFWColorOfTextHeader;

/**
 *  Color of text
 */
@property (nonatomic, retain) UIColor *mFWColorOfText;

/**
 *  Color for time label
 */
@property (nonatomic, retain) UIColor *mFWColorOfTime;

/**
 * Array for storing full-sized images to show in mFWPhotoBrowser
 * Used on mFWReplies, because mFWReplies#photos array was destroyed
 * every time user quits replies page, but photobrowser somehow
 * asynchronously tried to access it later and app crashed.
 */
@property (nonatomic, retain) NSMutableArray *mFWLargeImagesForBrowsingFromPreviews;

/**
 * Control property. Set it to NO if you do not want send user location data along the message
 */
@property BOOL isLocationTrackingEnabled;

/**
 * Application name to put into sharing message
 */
@property (nonatomic, retain) NSString *appName;

/**
 * Key for storing location enabled flag in User Defaults
 */
@property (nonatomic, strong) NSString *locationTrackingEnabledKey;

/**
 * Single "handle location" point for all mFWInputToolbar delegates
 */
-(BOOL)toggleGeolocationForToolbar:(mFWInputToolbar *)toolbar;

/**
 *  Get messages with Parent ID, Reply ID, Post ID and limit number
 *
 *  @param parentID Parent ID
 *  @param replyID  Reply ID
 *  @param postID   Post ID
 *  @param limit    Limit number
 */
  - (void)getMessagesWithParentID:(NSString *)parentID
                       andReplyID:(NSString *)replyID
                        andPostID:(NSString *)postID
                            limit:(NSInteger)limit
                          success:(mFWURLLoaderSuccessBlock )success_
                          failure:(mFWURLLoaderFailureBlock )failure_;

/**
 *  Post message
 *
 *  @param parentID    Parent ID
 *  @param replyID     Reply ID
 *  @param messageText Post ID
 *  @param images      Array of images
 *  @param success_    Success callback block
 *  @param failure_    Failure calback block
 */
  - (void)postMessageWithParentID:(NSString *)parentID
                       andReplyID:(NSString *)replyID
                         withText:(NSString *)messageText
                        andImages:(NSArray *)images
                          success:(mFWURLLoaderSuccessBlock )success_
                          failure:(mFWURLLoaderFailureBlock )failure_;


/**
 *  Increase sharing count for specified post
 *
 *  @param postID    Post ID
 *  @param success_    Success Block
 *  @param failure_    Failure Block
 */
- (void)increaseSharingCountForPost:(NSString *)postID
                            success:(mFWURLLoaderSuccessBlock )success_
                            failure:(mFWURLLoaderFailureBlock )failure_;

/**
 *  Get profile info
 *
 *  @param AccountID   Account ID
 *  @param AccountType Account type
 *  @param success_    Success callback block
 *  @param failure_    Failure calback block
 */
  - (void)getProfileInfoForUserWithAccountID:(NSString *)AccountID
                              andAccountType:(NSString *)AccountType
                                     success:(mFWURLLoaderSuccessBlock )success_
                                     failure:(mFWURLLoaderFailureBlock )failure_;

/**
 *  Send POST-message to server and get array
 *
 *  @param success_    Success callback block
 *  @param failure_    Failure calback block
 */
  - (void)getGalleryWithSuccess:(mFWURLLoaderSuccessBlock )success_
                        failure:(mFWURLLoaderFailureBlock )failure_;

/**
 *  Register user
 *
 *  @param parameters  Dictionary with registration parameters
 *  @param success_    Success callback block
 *  @param failure_    Failure calback block
 */
  - (void)registerUserWithParameters:(NSDictionary *)parameters
                             success:(mFWURLLoaderSuccessBlock )success_
                             failure:(mFWURLLoaderFailureBlock )failure_;

/**
 *  Login with email and password
 *
 *  @param email    Email
 *  @param password Password
 *  @param success_  Success callback block
 *  @param failure_  Failure calback block
 */
  - (void)loginWithEmail:(NSString *)email
             andPassword:(NSString *)password
                 success:(mFWURLLoaderSuccessBlock )success_
                 failure:(mFWURLLoaderFailureBlock )failure_;

/**
 *  Get messages from nearest location
 *
 *  @param radius    Radius (string representation)
 *  @param latitude  Latitude
 *  @param longitude Longitude
 *  @param postID    Post ID
 *  @param limit     Limit number
 *  @param success_  Success callback block
 *  @param failure_  Failure calback block
 */
  - (void)getMessagesInRadius:(NSString *)radius
                 fromLatitude:(float)latitude
                 andLongitude:(float)longitude
                   withPostID:(NSString *)postID
                        limit:(int)limit
                      success:(mFWURLLoaderSuccessBlock )success_
                      failure:(mFWURLLoaderFailureBlock )failure_;

/**
 *  Hide download indicator
 */
- (void)hideIndicator;

/**
 *  Show download indicator
 *
 *  @param mCenter Center point
 *  @param mView   Destination view
 */
- (UIView *)showIndicatorWithCenter:(CGPoint)mCenter inView:(UIView *)mView;

/**
 *  Shared instance (Singleton)
 *
 *  @return mFWConnection
 */
+ (mFWConnection *) sharedInstance;

/**
 * Method for checking if system location services enabled
 */
+(BOOL)areLocationServicesEnabled;

/**
 * Determines whether fanwall should track location
 * Decision based on whether system location service enabled
 * and whether user allows location tracking
 */
-(BOOL)shouldTrackLocation;

/**
 * Saves user desision allow or restrict sending his/her location data
 */
-(void)saveLocationTrackingEnabledToUserDefaults:(BOOL)locationTrackingEnabled;

/**
 * Set arrow on input toolbar lit or faded based on wheter geolocation is allowed
 */
-(void)refreshInputToolbarGeolocationIndicator:(mFWInputToolbar *)inputToolbar;

@end
