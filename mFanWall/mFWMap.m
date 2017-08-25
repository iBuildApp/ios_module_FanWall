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


#import "mFWMap.h"
#import "mWebVC.h"
#import <CoreLocation/CoreLocation.h>

@interface mFWMap ()
{
  UIBarButtonItem *backBarButton;
}
  @property(nonatomic, strong) WKWebView         *webView;
  @property(nonatomic, strong) CLLocationManager *locationManager;
  @property(nonatomic, copy  ) NSString          *content;
  @property(nonatomic, strong) mFWConnection     *FWConnection;
@end

@implementation mFWMap

@synthesize   mapPoints = _mapPoints,
                webView = _webView,
        locationManager = _locationManager,
                content = _content,
           FWConnection = _FWConnection;

- (id)init
{
  self = [super init];
  if ( self )
  {
    _mapPoints       = [[NSMutableArray alloc] init];
    _webView         = nil;
    _locationManager = nil;
    _content         = nil;
    _FWConnection    = nil;
    backBarButton    = nil;
  }
  return self;
}

- (void)dealloc
{
  if(backBarButton != nil){
    backBarButton = nil;
  }
}

#pragma mark -
#pragma mark view life cycle
- (void)viewDidLoad
{
  self.FWConnection = [mFWConnection sharedInstance];
  
  backBarButton = [[UIBarButtonItem alloc] init];
  backBarButton.title = self.navigationController.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"mFW_backToWallButtonTitle", @"Wall");
    
  self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
  
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.view.autoresizesSubviews = YES;
  
  self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  [self.view addSubview:self.webView];

  [super viewDidLoad];
  
  [self reload];
}

- (void)viewWillAppear:(BOOL)animated
{
  self.navigationController.navigationBar.topItem.backBarButtonItem = backBarButton;
    // before hiding / displaying tabBar we must remember its previous state
  self.tabBarIsHidden = [[self.tabBarController tabBar] isHidden];
  [[self.tabBarController tabBar] setHidden:!self.showTabBar];
  
  [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    // restore tabBar state
  [[self.tabBarController tabBar] setHidden:self.tabBarIsHidden];
  [super viewWillDisappear:animated];
}

#pragma mark -

- (NSDictionary *)mapMetrixForPoints:(NSArray *)arrayOfMapPoints
{
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
  // SET MAP CENTER
  double maxLat = -90.0f;
  double maxLng = -180.0f;
  double minLat =  90.0f;
  double minLng =  180.0f;
  
  for ( int i = 0; i < arrayOfMapPoints.count; i++ )
  {
    if ( [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"latitude"] doubleValue] > maxLat )
    {
      maxLat = [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
    }
    
    if ( [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"longitude"] doubleValue] > maxLng )
    {
      maxLng = [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
    }
    
    if ( [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"latitude"] doubleValue] < minLat )
    {
      minLat = [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
    }
    
    if ( [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"longitude"] doubleValue] < minLng )
    {
      minLng = [[[arrayOfMapPoints objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
    }
  }
  
  double cenLat = (maxLat + minLat) / 2.0f;
  double cenLng = (maxLng + minLng) / 2.0f;
  
  [result setValue:[NSString stringWithFormat:@"%f", cenLat] forKey:@"centerLatitude"];
  [result setValue:[NSString stringWithFormat:@"%f", cenLng] forKey:@"centerLongitude"];
  
  // SET MAP ZOOM
  int zoom = 1;
  float delta;
  ((fabs(maxLng - minLng)) > (fabs(maxLat - minLat))) ? (delta = fabs(maxLng - minLng)) : (delta = fabs(maxLat - minLat));
  
  if     (delta > (120))       zoom = 1;
  else if(delta > (60))        zoom = 1;
  else if(delta > (30))        zoom = 1;
  else if(delta > (15))        zoom = 2;
  else if(delta > (8))         zoom = 3;
  else if(delta > (4))         zoom = 4;
  else if(delta > (2))         zoom = 5;
  else if(delta > (1))         zoom = 6;
  else if(delta > (0.5))       zoom = 7;
  else if(delta > (0.25))      zoom = 8;
  else if(delta > (0.125))     zoom = 9;
  else if(delta > (0.0625))    zoom = 10;
  else if(delta > (0.03125))   zoom = 11;
  else if(delta > (0.015625))  zoom = 12;
  else if(delta > (0.0078125)) zoom = 13;
  else                         zoom = 14;

  [result setValue:[NSString stringWithFormat:@"%d", zoom] forKey:@"mapZoom"];
  
  return result;
}

- (void)handleCall:(NSString *)functionName
          argument:(NSString *)argument
              name:(NSString *)name
{
  if ( [[functionName lowercaseString] isEqualToString:@"gotourl"] )
  {
    mWebVCViewController *webVC = [[mWebVCViewController alloc] init];
    webVC.URL = [[argument copy] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    webVC.title = [[name copy] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    webVC.scalable = YES;
    webVC.webView.contentMode = UIViewContentModeScaleAspectFit;
    [self.navigationController pushViewController:webVC animated:YES];
    
  }
}

#pragma mark WKWebViewDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURLRequest *request = navigationAction.request;
    NSString *requestString = [[request URL] absoluteString];
    
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    NSString *function = (NSString*)[components objectAtIndex:0];
    NSString *argument;
    NSString *name;
    if ( [[function lowercaseString] isEqualToString:@"gotourl"] )
    {
        argument = [(NSString*)[components objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        name     = [(NSString*)[components objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self handleCall:function argument:argument name:name];
    }
}

#pragma mark -
- (void)didReceiveMemoryWarning
{
  NSLog(@"mFWMap didReceiveMemoryWarning!");
  [self.webView reload];
  [super didReceiveMemoryWarning];
}

- (void)reload
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NSError *error;
  
  self.content = [NSString stringWithContentsOfURL:[thisBundle URLForResource:@"_mapweb_page_mFW"
                                                                withExtension:nil]
                                          encoding:NSUTF8StringEncoding
                                             error:&error];
  
  NSString *points = [NSString string];
  
  // SET MAP POINTS
  
  CLLocationManager *locationManager = [[CLLocationManager alloc] init];
  locationManager.delegate = self;
  locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  locationManager.distanceFilter = kCLDistanceFilterNone;
  if ( !([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
         [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ))
  {
    [locationManager startUpdatingLocation];
    [locationManager stopUpdatingLocation];
  }
  CLLocation *location = [locationManager location];
  
  float longitude = location.coordinate.longitude ? location.coordinate.longitude : 1000.0f;
  float latitude = location.coordinate.latitude ? location.coordinate.latitude : 1000.0f;
  
  for ( int i = 0; i < self.mapPoints.count; ++i )
  {
    points = [points stringByAppendingString:@"myMap.points.push({point:\""];
    points = [points stringByAppendingString:[[[self.mapPoints objectAtIndex:i] objectForKey:@"title"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    points = [points stringByAppendingFormat:@"\",latitude:%f,longitude:%f", [[[self.mapPoints objectAtIndex:i] objectForKey:@"latitude"] doubleValue], [[[self.mapPoints objectAtIndex:i] objectForKey:@"longitude"] doubleValue]];
    
    if ( [[self.mapPoints objectAtIndex:i] objectForKey:@"subtitle"]) points = [points stringByAppendingFormat:@",details:\"%@\"", [[[self.mapPoints objectAtIndex:i] objectForKey:@"subtitle"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    
    if ( [[self.mapPoints objectAtIndex:i] objectForKey:@"description"]) points = [points stringByAppendingFormat:@",url:\"%@\"", [[[self.mapPoints objectAtIndex:i] objectForKey:@"description"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    
    points = [points stringByAppendingString:@"});"];
	}
  
  points = [points stringByAppendingString:@"myMap.points.push({point:\""];
  points = [points stringByAppendingString:[self.FWConnection.mFWUserName stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
  points = [points stringByAppendingFormat:@"\",latitude:%f,longitude:%f", latitude, longitude];
  
  points = [points stringByAppendingFormat:@",details:\"%@\"", [@"-" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
  
  NSString *aURL = nil;
  if ( [self.FWConnection.mFWAccountType isEqualToString:@"facebook"] )
  {
    aURL = [NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@", self.FWConnection.mFWAccountID];
  }
  if ( [self.FWConnection.mFWAccountType isEqualToString:@"twitter"] )
  {
    aURL = [NSString stringWithFormat:@"https://twitter.com/account/redirect_by_id?id=%@", self.FWConnection.mFWAccountID];
  }
  
  points = [points stringByAppendingFormat:@",url:\"%@\"", [aURL stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
  
  points = [points stringByAppendingFormat:@",icon:1"];
  
  points = [points stringByAppendingString:@"});"];
  points = [points stringByReplacingOccurrencesOfString:@"\r\n" withString:@"<br />"];
  points = [points stringByReplacingOccurrencesOfString:@"\r"   withString:@"<br />"];
  points = [points stringByReplacingOccurrencesOfString:@"\n"   withString:@"<br />"];
  
  self.content = [self.content stringByReplacingOccurrencesOfString:@"__RePlAcE-Points__" withString:points];
  
  if ( latitude == 1000.0f && longitude == 1000.0f )
  {
    self.content = [self.content stringByReplacingOccurrencesOfString:@"__RePlAcE-Lat__"
                                                           withString:[[self mapMetrixForPoints:self.mapPoints] objectForKey:@"centerLatitude"]];
    self.content = [self.content stringByReplacingOccurrencesOfString:@"__RePlAcE-Lng__"
                                                           withString:[[self mapMetrixForPoints:self.mapPoints] objectForKey:@"centerLongitude"]];
  } else {
    self.content = [self.content stringByReplacingOccurrencesOfString:@"__RePlAcE-Lat__"    withString:[NSString stringWithFormat:@"%f", latitude]];
    self.content = [self.content stringByReplacingOccurrencesOfString:@"__RePlAcE-Lng__"    withString:[NSString stringWithFormat:@"%f", longitude]];
  }
  
  self.content = [self.content stringByReplacingOccurrencesOfString:@"__RePlAcE-Zoom__"
                                                         withString:[[self mapMetrixForPoints:self.mapPoints] objectForKey:@"mapZoom"]];
  
  self.webView.navigationDelegate = self;
  
  [self.webView loadHTMLString:self.content baseURL:nil];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark -
#pragma mark autorotate handlers
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

@end
