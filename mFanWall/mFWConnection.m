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


#import "mFWConnection.h"
#import "NSObject+AssociatedObjects.h"
#import "appconfig.h"
#import <auth_Share/auth_Share.h>
#import <auth_Share/auth_ShareLoginVC.h>
#import <CoreLocation/CLLocationManager.h>

#define kOpenLocationServicesAlertTag 100

@interface mFWConnection () {
  NSUserDefaults *UD;
}
//  @property (nonatomic, strong) NSMutableData *receivedData;
  @property (nonatomic, strong) UIView                  *spinnerView;
  @property (nonatomic, strong) UIActivityIndicatorView *spinner;

 /**
  * Location manager to retreive user location when sending a message
  */
  @property (nonatomic, strong, readwrite) CLLocationManager *locationManager;

/**
 * Used to store toolbar link when prompting to enable when-in-use geolocation
 * If permission is granted, we move toolbar's indicator to active state
 */
  @property (nonatomic, strong, readwrite) mFWInputToolbar *lastToolbar;
@end

#define mFWBaseHOST appIBuildAppHostName()
#define mFWBaseURL  [[@"http://" stringByAppendingString:appIBuildAppHostName()] stringByAppendingString:@"/mdscr/fanwall/"]
#define mFWAuthBaseURL  [[@"http://" stringByAppendingString:appIBuildAppHostName()] stringByAppendingString:@"/mdscr/user/"]
#define mFWIncreaseSharingQtyURL [mFWBaseURL stringByAppendingString:@"sharing_increment/"]

@implementation mFWConnection

@synthesize isLoggedIn;
@synthesize isReceivedError;
//@synthesize finished;
@synthesize loginCanceled;
//@synthesize serverResponse = _serverResponse;
@synthesize serverMessage  = _serverMessage;

@synthesize mFWAppID       = _mFWAppID;
@synthesize mFWModuleID    = _mFWModuleID;

@synthesize mFWCanEdit     = _mFWCanEdit;

@synthesize mFWAccountID   = _mFWAccountID;
@synthesize mFWAccountType = _mFWAccountType;
@synthesize mFWUserName    = _mFWUserName;
@synthesize mFWAvatar      = _mFWAvatar;

@synthesize afterPost;
@synthesize afterReply;
@synthesize afterReply2;
@synthesize requiresRequest;

@synthesize activeCell  = _activeCell;
@synthesize activeImage = _activeImage;
//@synthesize receivedData = _receivedData;

@synthesize spinnerView = _spinnerView;
@synthesize     spinner = _spinner;


@synthesize mFWColorOfBackground;
@synthesize mFWColorOfWallTime;
@synthesize mFWColorOfTextHeader;
@synthesize mFWColorOfText;
@synthesize mFWColorOfTime;



static mFWConnection *cmFWConnection = nil;

+ (mFWConnection *)sharedInstance
{
  @synchronized(self)
  {
    if ( cmFWConnection == nil )
      cmFWConnection = [[mFWConnection alloc] init];
  }
  return cmFWConnection;
}

- (void)dealloc
{


  [self.spinner removeFromSuperview];
  
  [self.spinnerView removeFromSuperview];

  
  [self.locationManager stopUpdatingLocation];
  self.locationManager.delegate = nil;

  
}

- (id)init
{
  self = [super init];
  _mFWAppID       = nil;
  _mFWModuleID    = nil;
  _mFWCanEdit     = nil;
  _mFWAccountID   = nil;
  _mFWAccountType = nil;
  _mFWUserName    = nil;
  _mFWAvatar      = nil;
  
  _spinnerView    = nil;
  _spinner        = nil;

  _serverMessage  = nil;

  _activeCell     = nil;
  _activeImage    = nil;
  _mFWLargeImagesForBrowsingFromPreviews = nil;

  UD = [NSUserDefaults standardUserDefaults];
  self.isReceivedError = NO;
  self.isLoggedIn = NO;
  self.loginCanceled = NO;
  
  self.afterPost = NO;
  self.afterReply = NO;
  self.afterReply2 = NO;
  
  self.requiresRequest = NO;
  
  NSString *accountType = [UD objectForKey: @"mAccountType"];
  if (accountType
      && ([accountType isEqualToString:@"none"] || [accountType isEqualToString:@"guest"]))
  {
    self.mFWAccountID   = @"";
    self.mFWAccountType = @"";
    self.mFWUserName    = @"";
    self.mFWAvatar      = @"";
  }
  else
  {
    self.mFWAccountID   = ([UD objectForKey:@"mAccountID"]   ? [UD objectForKey:@"mAccountID"]   : @"");
    self.mFWAccountType = ([UD objectForKey:@"mAccountType"] ? [UD objectForKey:@"mAccountType"] : @"");
    self.mFWUserName    = ([UD objectForKey:@"mUserName"]    ? [UD objectForKey:@"mUserName"]    : @"");
    self.mFWAvatar      = ([UD objectForKey:@"mAvatar"]      ? [UD objectForKey:@"mAvatar"]      : @"");
  }

  self.mFWColorOfBackground = [UIColor colorWithRed:243.0f/255.0f green:243.0f/255.0f blue:243.0f/255.0f alpha:1.0f];
  self.mFWColorOfWallTime   = [UIColor whiteColor];
  self.mFWColorOfTextHeader = [UIColor colorWithRed: 53.0f/256.0f green: 53.0f/256.0f blue: 53.0f/256.0f alpha:1.0f];;
  self.mFWColorOfText       = [UIColor colorWithRed:102.0f/256.0f green:102.0f/256.0f blue:102.0f/256.0f alpha:1.0f];
  self.mFWColorOfTime       = [UIColor colorWithRed:155.0f/256.0f green:155.0f/256.0f blue:155.0f/256.0f alpha:1.0f];
  
  if ( self.mFWAccountID.length && self.mFWAccountType.length )
    self.isLoggedIn = YES;
  
  self.mFWLargeImagesForBrowsingFromPreviews = [NSMutableArray array];
  
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  self.locationManager.distanceFilter = kCLDistanceFilterNone;
  
  self.isLocationTrackingEnabled = [mFWConnection areLocationServicesEnabled];
  
  _appName = nil;
  _locationTrackingEnabledKey = nil;
  _lastToolbar = nil;
  
  return self;
}

- (void)getMessagesWithParentID:(NSString *)parentID
                     andReplyID:(NSString *)replyID
                      andPostID:(NSString *)postID
                          limit:(NSInteger)limit
                        success:(mFWURLLoaderSuccessBlock )success_
                        failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Request for Messages");
  
  NSString *requestURL = [mFWBaseURL stringByAppendingFormat:@"%@/%@/%@/%@/%@/%ld/%@/%@/",
                          self.mFWAppID,
                          self.mFWModuleID,
                          parentID,
                          replyID,
                          postID,
                          (long)limit,
                          self.mFWAppID,
                          appToken()];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  
  [request setHTTPMethod:@"GET"];
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];

  // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
}

- (void)postMessageWithParentID:(NSString *)parentID
                     andReplyID:(NSString *)replyID
                       withText:(NSString *)messageText
                      andImages:(NSArray *)images
                        success:(mFWURLLoaderSuccessBlock )success_
                        failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Try to post message");
  
  NSString *boundary = [NSString stringWithFormat:@"---###---%@--##--%@--##--%@-#-%@---###---BOUNDARY---###", self.mFWAppID,
                                                                                                              self.mFWModuleID,
                                                                                                              parentID,
                                                                                                              replyID];
  NSMutableData *postBody = [NSMutableData data];
  NSString *postString = nil;
  
  auth_Share *auth = [auth_Share sharedInstance];
  auth.messageProcessingBlock = nil;
  
  postString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"app_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.mFWAppID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"token\"\r\n\r\n"];
  postString = [postString stringByAppendingString:appToken()];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"module_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.mFWModuleID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"parent_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:parentID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"reply_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:replyID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"account_type\"\r\n\r\n"];
  postString = [postString stringByAppendingString:auth.user.type];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"account_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:auth.user.ID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"user_name\"\r\n\r\n"];
  postString = [postString stringByAppendingString:auth.user.name];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"user_avatar\"\r\n\r\n" ];
  postString = [postString stringByAppendingString:auth.user.avatar];
  
  float latitude = 1000.0f;
  float longitude = 1000.0f;
  
  if(self.isLocationTrackingEnabled){
    if([mFWConnection areLocationServicesEnabled])
    {
      dispatch_async(GCDBackgroundThread, ^{
        [self.locationManager startUpdatingLocation];
      });

      CLLocation *location = [self.locationManager location];
      
      [self.locationManager stopUpdatingLocation];
      
      longitude = location.coordinate.longitude ? location.coordinate.longitude : longitude;
      latitude = location.coordinate.latitude ? location.coordinate.latitude : latitude;
      
      NSLog(@"mFWConnection LOCATION %@", [location description]);
    }
  }
  
  NSLog(@"mFWConnection long %f lat %f", longitude, latitude);
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"latitude\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"%f", latitude]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"longitude\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"%f", longitude]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"text\"\r\n\r\n"];
  postString = [postString stringByAppendingString:messageText];
  
  [postBody appendData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
  
  for ( int i = 0; i < images.count; i++ )
  {
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"images\"; filename=\"image%d.jpg\"\r\n", i] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:UIImageJPEGRepresentation([images objectAtIndex:i], 0.75f)];
  }
  
  [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSString *requestURL = mFWBaseURL;
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  [request setHTTPMethod:@"POST"];
  
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
  [request setValue:mFWBaseHOST forHTTPHeaderField:@"Host"];
  [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postBody.length] forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPBody:postBody];
  
  
  // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
}


- (void)increaseSharingCountForPost:(NSString *)postID
                            success:(mFWURLLoaderSuccessBlock )success_
                            failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Try to increase sharing count for post %@", postID);
  
  NSString *boundary = [NSString stringWithFormat:@"---###---%@--##--%@--##--%@-###---BOUNDARY---###", self.mFWAppID,
                        self.mFWModuleID,
                        postID];
  
  NSMutableData *postBody = [NSMutableData data];
  NSString *postString = nil;
  
  postString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"app_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.mFWAppID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"token\"\r\n\r\n"];
  postString = [postString stringByAppendingString:appToken()];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"module_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.mFWModuleID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"post_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:postID];
  
  
  [postBody appendData:[postString dataUsingEncoding:NSUTF8StringEncoding]];

  
  [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSString *requestURL = mFWIncreaseSharingQtyURL;
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  [request setHTTPMethod:@"POST"];
  
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
  [request setValue:mFWBaseHOST forHTTPHeaderField:@"Host"];
  [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postBody.length] forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPBody:postBody];
  
  
    // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
  
}



- (void)getProfileInfoForUserWithAccountID:(NSString *)AccountID
                            andAccountType:(NSString *)AccountType
                                   success:(mFWURLLoaderSuccessBlock )success_
                                   failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Request for ProfileInfo");
  
  NSString *requestURL = [mFWBaseURL stringByAppendingFormat:@"%@/%@/getprofileinfo/%@/%@/%@/%@/", self.mFWAppID, self.mFWModuleID, AccountType, AccountID, self.mFWAppID, appToken()];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  
  [request setHTTPMethod:@"GET"];
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];

  // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
}

- (void)getGalleryWithSuccess:(mFWURLLoaderSuccessBlock )success_
                      failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Request for Gallery");
  
  NSString *requestURL = [mFWBaseURL stringByAppendingFormat:@"%@/%@/gallery/%@/%@/", self.mFWAppID, self.mFWModuleID, self.mFWAppID,
                          appToken()];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  
  [request setHTTPMethod:@"GET"];
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  
  // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
}

- (void)registerUserWithParameters:(NSDictionary *)parameters
                           success:(mFWURLLoaderSuccessBlock )success_
                           failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Try to register user");
  
  NSString *boundary = [NSString stringWithFormat:@"---###---%@--##--%@--###---BOUNDARY---###", self.mFWAppID, self.mFWModuleID];
  NSMutableData *postBody = [NSMutableData data];
  NSString *postString = nil;
  
  postString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"firstname\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"firstname"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"lastname\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"lastname"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"email\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"email"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"password\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"password"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"password_confirm\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"password_confirm"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"token\"\r\n\r\n"];
  postString = [postString stringByAppendingString:appToken()];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"app_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.mFWAppID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary]];
  
  [postBody appendData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSString *requestURL = [mFWAuthBaseURL stringByAppendingString:@"signup"];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  [request setHTTPMethod:@"POST"];
  
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
  [request setValue:mFWBaseHOST forHTTPHeaderField:@"Host"];
  [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postBody.length] forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPBody:postBody];
  
  // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
}

- (void)loginWithEmail:(NSString *)email
           andPassword:(NSString *)password
               success:(mFWURLLoaderSuccessBlock )success_
               failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Request for login");
  
  NSString *boundary = [NSString stringWithFormat:@"---###---%@--##--%@--###---BOUNDARY---###", self.mFWAppID, self.mFWModuleID];
  NSMutableData *postBody = [NSMutableData data];
  NSString *postString = nil;
  
  postString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
  
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"login\"\r\n\r\n"];
  postString = [postString stringByAppendingString:email];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"password\"\r\n\r\n"];
  postString = [postString stringByAppendingString:password];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"token\"\r\n\r\n"];
  postString = [postString stringByAppendingString:appToken()];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"app_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.mFWAppID];
  
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary]];
  
  [postBody appendData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSString *requestURL = [mFWAuthBaseURL stringByAppendingString:@"login"];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  [request setHTTPMethod:@"POST"];
  
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
  [request setValue:mFWBaseHOST forHTTPHeaderField:@"Host"];
  [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postBody.length] forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPBody:postBody];
  
  // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
}

- (void)getMessagesInRadius:(NSString *)radius
               fromLatitude:(float)latitude
               andLongitude:(float)longitude
                 withPostID:(NSString *)postID
                      limit:(int)limit
                    success:(mFWURLLoaderSuccessBlock )success_
                    failure:(mFWURLLoaderFailureBlock )failure_
{
  NSLog(@"Request for Messages");
  
  NSString *requestURL = [mFWBaseURL stringByAppendingFormat:@"%@/%@/getnear/%@/%f/%f/%@/%d", self.mFWAppID, self.mFWModuleID, postID, latitude, longitude, radius, limit];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  
  [request setHTTPMethod:@"GET"];
  [request setValue:@"FanWall/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  
  // create new URL request...
  [[mFWURLLoader alloc] initWithRequest:request
                                 success:success_
                                 failure:failure_];
}

- (UIView *)showIndicatorWithCenter:(CGPoint)mCenter inView:(UIView *)mView
{
  if ( [self.spinnerView superview] != mView )
  {
    [self hideIndicator];
    
    const CGSize spinnerSize = CGSizeMake( 100.f, 100.f);
    self.spinnerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, spinnerSize.width, spinnerSize.height)];
    self.spinnerView.alpha = 0.7f;
    self.spinnerView.backgroundColor = [UIColor blackColor];
    self.spinnerView.layer.cornerRadius = 6.0f;
    self.spinnerView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.spinnerView.layer.borderWidth = 1.0f;
    self.spinnerView.layer.masksToBounds = YES;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                                         UIActivityIndicatorViewStyleWhiteLarge];
    
    self.spinner.frame = CGRectMake(floorf(spinnerSize.width / 2.f - self.spinner.frame.size.width / 2.f),
                                    floorf(spinnerSize.height / 2.f - self.spinner.frame.size.height / 2.f),
                                    self.spinner.frame.size.width,
                                    self.spinner.frame.size.height);
    [self.spinnerView addSubview:self.spinner];
    [mView addSubview:self.spinnerView];
  }
  self.spinnerView.center = mCenter;
  [mView bringSubviewToFront:self.spinnerView];
  [self.spinner startAnimating];
    
  return self.spinnerView;
}

- (void)hideIndicator
{
  [self.spinner stopAnimating];
  [self.spinner removeFromSuperview];
  self.spinner = nil;
  
  [self.spinnerView removeFromSuperview];
  self.spinnerView = nil;
}

-(BOOL)toggleGeolocationForToolbar:(mFWInputToolbar *)toolbar{
  BOOL geolocationEnabled = [self toggleGeolocation];
  [toolbar indicateGeolocationIsEnabled:geolocationEnabled];
  
  return geolocationEnabled;
}

/**
 * @return BOOL will be the user location sent along the message?
 */
- (BOOL)toggleGeolocation
{
  // check for locationServicesEnabled
  if(![mFWConnection areLocationServicesEnabled])
  {
    [self notifyLocationServicesDisabled];
    return NO;
  } else {
    return (self.isLocationTrackingEnabled = !self.isLocationTrackingEnabled);
  }
}

-(void)notifyLocationServicesDisabled
{
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
  {
    NSString *title;
    title = NSBundleLocalizedString(@"mFW_locationDisabledTitle", nil );
    NSString *message = NSBundleLocalizedString(@"mFW_locationDisabledOpenServicesSettingsMessage", nil );
  
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSBundleLocalizedString(@"mFW_locationDisabledCancelButtonTitle", nil )
                                              otherButtonTitles:NSBundleLocalizedString(@"mFW_locationDisabledSettingsButtonTitle", nil ), nil];
    
    alertView.tag = kOpenLocationServicesAlertTag;
    
    [alertView show];
  }
  else
  {
    UIAlertView *locationAlert = [[UIAlertView alloc] initWithTitle:NSBundleLocalizedString(@"mFW_locationDisabledTitle", nil )
                                                            message:NSBundleLocalizedString(@"mFW_locationDisabledMessage", nil )
                                                           delegate:nil
                                                  cancelButtonTitle:NSBundleLocalizedString(@"mFW_locationDisabledOkButtonTitle", nil )
                                                  otherButtonTitles:nil];
    [locationAlert show];
  }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
  if (alertView.tag == kOpenLocationServicesAlertTag && buttonIndex == 1)
  {
    // Send the user to the Settings for this app
    NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:settingsURL];
  }
}
}

#pragma mark - Location

+(BOOL)areLocationServicesEnabled
{
  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
  
  BOOL enabled = ( [CLLocationManager locationServicesEnabled] &&
                  (status == kCLAuthorizationStatusAuthorizedAlways ||
                   status == kCLAuthorizationStatusAuthorizedWhenInUse ||
                   status == kCLAuthorizationStatusAuthorizedAlways)
                  );
  
  return enabled;
}

-(BOOL)shouldTrackLocation
{
  if(self.locationTrackingEnabledKey){
    
    BOOL locationServicesEnabled = [mFWConnection areLocationServicesEnabled];
    
    if([UD objectForKey:self.locationTrackingEnabledKey]){
      return locationServicesEnabled && [UD boolForKey:self.locationTrackingEnabledKey];
    }
    
    return locationServicesEnabled;
  }
  return YES;
}

-(void)saveLocationTrackingEnabledToUserDefaults:(BOOL)locationTrackingEnabled
{
  if(self.locationTrackingEnabledKey){
    [UD setBool:locationTrackingEnabled forKey:self.locationTrackingEnabledKey];
    [UD synchronize];
  }
}

-(void)refreshInputToolbarGeolocationIndicator:(mFWInputToolbar *)inputToolbar
{
  BOOL shouldTrackLocation = [self shouldTrackLocation];
  [inputToolbar indicateGeolocationIsEnabled:shouldTrackLocation];
  self.isLocationTrackingEnabled = shouldTrackLocation;
  
  if(shouldTrackLocation){
    if(!self.locationManager.location){
      [self.locationManager startUpdatingLocation];
    }
  } else {
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
      if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        [self.locationManager requestWhenInUseAuthorization];
      } else {
        [self.locationManager startUpdatingLocation];
      }
    }
  }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
  [manager stopUpdatingLocation];
  NSLog(@"mFWConnection locationManager newLocation %f",newLocation.coordinate.latitude);
  NSLog(@"mFWConnection locationManager newLocation %f",newLocation.coordinate.longitude);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
  [manager stopUpdatingLocation];
  NSLog(@"mFWConnection locationManager did fail with error: %@", [error description]);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if(self.lastToolbar){
      [self refreshInputToolbarGeolocationIndicator:self.lastToolbar];
      self.lastToolbar = nil;
    }
}

@end
