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


#import "mFanWall.h"
#import "mFWPostCell.h"
#import "mFWReplies.h"
#import "mFWProfile.h"
#import "mFWMap.h"
#import "mFanWallBundle.h"
#import "TBXML.h"
#import "mFWSettings.h"
#import "mFWPhotosVC.h"
#import "appconfig.h"

#import "reachability.h"

#import "EGORefreshTableHeaderView.h"
#import <Smartling.i18n/SLLocalization.h>
#import "mFWInputToolbar.h"

#import "mFWImageProvider.h"
#import "mFWPhotoBrowser.h"
#import "mFWSocialButtonWithoutLikes.h"

#import <auth_Share/auth_Share.h>
#import <auth_Share/auth_ShareLoginVC.h>

#import <objc/runtime.h>

#import "UIImage+color.h"
#import "NSString+size.h"

#define kButtonsBarHeight 44.f
#define kSpaceBetweenIconAndButtonName 10.0f
#define kSeparatorWidth 1.0f
#define kIconWidthAndHeight 24.0f
#define kSeparatorHeight 24.0f
#define kSeparatorPaddingInButtonsBar ((kButtonsBarHeight - kSeparatorHeight) / 2)
#define kSeparatorColor [UIColor colorWithWhite:1.0f alpha:0.4f]

#define kRefreshHeaderViewArrowPadding  11.0f
#define kRefreshHeaderViewArrowHeight   53.0f
#define kRefreshHeaderViewHeight        (kRefreshHeaderViewArrowHeight + 2 * kRefreshHeaderViewArrowPadding)

#define kInputToolbarMaskViewTag 12345

#define tabsBackgroundBottomSpacerColor [UIColor colorWithWhite:1.0f alpha:0.2f]
#define tabsBackgroundSpacerHeight 1.0f

#define kOpenLocationServicesAlertTag 100

#define kAttachedImageViewTag 438452

#define kSpinnerViewTag 7685464

typedef enum {
  BottomBar,
  PostScreen,
  None
} AuthenticationRequestSource;

typedef enum {
  LoadPostsAtStart,
  LoadNewerPosts,
  LoadOlderPosts,
  ReloadExistingPosts
} PostsLoadingStrategy;

@interface mFanWallViewController()
{
  BOOL keyboardIsVisible;
  BOOL tabsBackgroundVisible;
  
  NSString *enteredPostText;
  NSArray *messagePostImages;
  
  auth_Share *aSha;
  NSUserDefaults *UD;
  BOOL canEdit;
  CGPoint downloadIndicatorCenter;
  
  /**
   * States whether we created the wall or cancelled creation due to the abscence of the Internet
   */
  BOOL wallCreated;
  
  /**
   * States whether we need to redraw cell manually atfer pressing like button
   */
  BOOL fbLikeNeedReloadData;
  
  /**
   * We can have some messages removed at server and to accomodate
   */
  NSUInteger rowsToDelete;
}

@property(nonatomic, strong) mFWSettings *fwSettings;
/**
 *  Main widget tableView
 */
@property(nonatomic, strong) UITableView    *wall;

/**
 *  GridView for photo gallery thumbnails
 */
@property(nonatomic, strong) NRGridView     *gallery;

/**
 *  View for page content
 */
@property(nonatomic, strong) UIView         *pageContent;


// UI controls
@property(nonatomic, strong) UILabel        *noMessagesLabel;

// current state ID's
@property(nonatomic, strong) NSString       *firstPostID;
@property(nonatomic, strong) NSString       *lastPostID;
@property(nonatomic, strong) NSString       *postID;

@property(nonatomic, strong) NSMutableArray *s_posts;
@property(nonatomic, strong) NSMutableArray *s_images;

@property(nonatomic, strong) UIButton       *mapButton;
@property(nonatomic, strong) UIButton       *photosButton;



@property(nonatomic, strong) UIImage        *mapIcon;
@property(nonatomic, strong) UIImage        *photosIcon;

@property(nonatomic, strong) mFWConnection *FWConnection;
@property(nonatomic, strong) Reachability  *hostReachable;
@property(nonatomic, assign) NetworkStatus  hostStatus;

@property(nonatomic, assign) NSInteger limit;
@property(nonatomic, assign) BOOL onLoadingView;
@property(nonatomic, assign) BOOL wallIsEmpty;
@property(nonatomic, assign) BOOL tabBarIsHidden;

@property(nonatomic, assign) BOOL reachable;

@property (nonatomic, assign) BOOL reloading;
@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;

/**
 *  Toolbar for entering post message
 */
@property (nonatomic, strong) mFWInputToolbar *inputToolbar;

@property (nonatomic, strong) mFWImageProvider *imageProvider;
@property (nonatomic, strong) NSString *pageTitle;


@property (nonatomic, strong) UIView *tabsBackground;

@property (nonatomic, strong) NSMutableSet *facebookLikedItems;
@property (nonatomic, strong) NSMutableDictionary *facebookLikesForPosts;
@property (nonatomic, strong) NSMutableDictionary *sharesCountForPosts;

@property (nonatomic, strong) NSString *facebookLikedItemsUDKey;
@property (nonatomic, strong) NSString *facebookLikesForPostsUDKey;
@property (nonatomic, strong) NSString *sharesCountForPostsUDKey;

@property (nonatomic, strong) UIImage *placeholderImage;

@end

@implementation mFanWallViewController
{
  NSDateFormatter *dateFormatter;
  NSDateFormatter *timeFormatter;
  
  AuthenticationRequestSource authenticationRequestSource;
  
  BOOL shouldComplainIfTextIsEmpty;
  
  /**
   * Indicates that we did not loaded the oldest reply and therefore may
   * proceed sending requests and show loading indicator
   */
  BOOL mayLoadOlderPosts;
  
  BOOL shouldScrollToTop;
}

@synthesize
fwSettings = _fwSettings,
array = _array,
appID = _appID,
wall = _wall,
gallery = _gallery,
pageContent = _pageContent,

//-----------------------------------
firstPostID = _firstPostID,
lastPostID = _lastPostID,
postID = _postID,
//-----------------------------------
s_posts = _s_posts,
s_images = _s_images,
//-----------------------------------

mapButton = _mapButton,
photosButton = _photosButton,

mapIcon = _mapIcon,
photosIcon = _photosIcon,
//---------------------------------
FWConnection = _FWConnection,
hostReachable = _hostReachable,
hostStatus,
limit,
reachable,
onLoadingView,
tabBarIsHidden,
wallIsEmpty;

#pragma mark -
#pragma mark xml configuration parser

+ (void)parseXML:(NSValue *)xmlElement_
      withParams:(NSMutableDictionary *)params_
{
  TBXMLElement element;
  [xmlElement_ getValue:&element];
  
  NSMutableArray *contentArray = [NSMutableArray array];
  const NSArray *tags = [NSArray arrayWithObjects:@"canedit", @"near", @"module_id", nil];
  NSMutableDictionary *elementsDictionary = [NSMutableDictionary dictionary];
  
  for( NSString *tagName in tags )
  {
    TBXMLElement *tagElement = [TBXML childElementNamed:tagName parentElement:&element];
    if ( tagElement )
      [elementsDictionary setObject:[TBXML textForElement:tagElement] forKey:tagName];
  }
  
  NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
  TBXMLElement *data = &element;
  TBXMLElement *dataChild = data->firstChild;
  
  while(dataChild)
  {
    if ([[TBXML elementName:dataChild] isEqualToString:@"colorskin"])
    {
      NSMutableDictionary *colorSkin = [NSMutableDictionary dictionary];
      
      if ([TBXML childElementNamed:@"color1" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color1" parentElement:dataChild]] forKey:@"color1"];
      
      if ([TBXML childElementNamed:@"color2" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color2" parentElement:dataChild]] forKey:@"color2"];
      
      if ([TBXML childElementNamed:@"color3" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color3" parentElement:dataChild]] forKey:@"color3"];
      
      if ([TBXML childElementNamed:@"color4" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color4" parentElement:dataChild]] forKey:@"color4"];
      
      if ([TBXML childElementNamed:@"color5" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color5" parentElement:dataChild]] forKey:@"color5"];
      
      [tmp setValue:colorSkin forKey:@"colorskin"];
    }
    
    if ( tmp.count )
      [contentArray addObject:[tmp copy]];
    [tmp removeAllObjects];
    
    dataChild = dataChild->nextSibling;
  };
  
  [contentArray addObject:elementsDictionary];
  [params_ setObject:contentArray forKey:@"data"];
}

#pragma mark -
#pragma mark set module params
- (void)setParams:(NSMutableDictionary *)inputParams
{
  if (inputParams != nil)
  {
    self.pageTitle = [inputParams objectForKey:@"title"];
    self.array = [inputParams objectForKey:@"data"];
    self.appID = [inputParams objectForKey:@"app_id"];
    
    self.FWConnection = [mFWConnection sharedInstance];
    
    self.FWConnection.mFWAppID = self.appID;
    
    self.hostReachable = [Reachability reachabilityWithHostName:[appIBuildAppHostName() stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    self.hostStatus = [self.hostReachable currentReachabilityStatus];
    
    self.FWConnection.appName = [inputParams objectForKey:@"appName"];
    
    NSString *widgetId = [inputParams objectForKey:@"widget_id"];
    self.FWConnection.locationTrackingEnabledKey = [NSString stringWithFormat:@"%@%@", @"mFanWall_locationTrackingEnabledForWidget_", widgetId];
    
    self.facebookLikedItemsUDKey = [NSString stringWithFormat:@"%@%@", @"mFanWall_facebookLikedItemsForWidget_", widgetId];
    self.facebookLikesForPostsUDKey = [NSString stringWithFormat:@"%@%@", @"mFanWall_facebookLikesForPostsForWidget_", widgetId];
    self.sharesCountForPostsUDKey = [NSString stringWithFormat:@"%@%@", @"mFanWall_sharesCountForPostsForWidget_", widgetId];
    
    
    for ( int i = 0; i < self.array.count; i++ )
    {
      NSDictionary *currentDict = [self.array objectAtIndex:i];
      
      if ( [currentDict objectForKey:@"module_id"] )
        self.FWConnection.mFWModuleID = [currentDict objectForKey:@"module_id"];
      
      if ( [currentDict objectForKey:@"canedit"] )
        self.FWConnection.mFWCanEdit  = [currentDict objectForKey:@"canedit"];
      
      
      NSDictionary *colorskinDict = [currentDict objectForKey:@"colorskin"];
      if ( [currentDict objectForKey:@"colorskin"] )
      {
        if ( [[colorskinDict objectForKey:@"color1"] asColor] )
          self.FWConnection.mFWColorOfBackground = [[colorskinDict objectForKey:@"color1"] asColor];
        
        if ( [[colorskinDict objectForKey:@"color2"] asColor] )
          self.FWConnection.mFWColorOfWallTime   = [[colorskinDict objectForKey:@"color2"] asColor];
        
        if ( [[colorskinDict objectForKey:@"color3"] asColor] )
          self.FWConnection.mFWColorOfTextHeader = [[colorskinDict objectForKey:@"color3"] asColor];
        
        if ( [[colorskinDict objectForKey:@"color4"] asColor] )
          self.FWConnection.mFWColorOfText       = [[colorskinDict objectForKey:@"color4"] asColor];
        
        if ( [[colorskinDict objectForKey:@"color5"] asColor] )
          self.FWConnection.mFWColorOfTime       = [[colorskinDict objectForKey:@"color5"] asColor];
      }
    }
    
  }
}

#pragma mark -
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
    _fwSettings = [[mFWSettings alloc] init];
    onLoadingView  = NO;
    wallIsEmpty    = NO;
    tabBarIsHidden = NO;
    reachable      = YES;
    
    limit          = -1;
    _appID   = nil;
    _array   = nil;
    _wall    = nil;
    _gallery = nil;
    
    _pageContent  = nil;
    
    _noMessagesLabel       = nil;
    _pageContent       = nil;
    //------------------------
    _firstPostID   = nil;
    _lastPostID    = nil;
    _postID        = nil;
    //------------------------
    _s_posts  = nil;
    _s_images = nil;
    //------------------------

    _mapButton        = nil;
    _photosButton     = nil;
    _mapIcon          = nil;
    _photosIcon       = nil;
    //------------------------
    _FWConnection     = nil;
    _hostReachable    = nil;
    hostStatus        = NotReachable;
    _imageProvider = nil;
    
    authenticationRequestSource = None;
    canEdit = NO;
    _pageTitle = nil;
    
    _facebookLikedItems = nil;
    _facebookLikesForPosts = nil;
    _sharesCountForPosts = nil;
    
    mayLoadOlderPosts = YES;
    
    wallCreated = NO;
    fbLikeNeedReloadData = NO;
    _placeholderImage = kPlaceholderImage;
    
    _facebookLikedItemsUDKey = nil;
    _facebookLikesForPostsUDKey = nil;
    _sharesCountForPostsUDKey = nil;
    
    rowsToDelete = 0;
    shouldScrollToTop = NO;
    
    
    UD = [NSUserDefaults standardUserDefaults];
  }
  return self;
}

- (void)dealloc
{
  //-----------------------
  //----------------------
  
  
  
  
  
  if(dateFormatter != nil){
    dateFormatter = nil;
  }
  
  if(timeFormatter != nil){
    timeFormatter = nil;
  }
  
  
  
  
  
  
  aSha.delegate = nil;
  aSha.viewController = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
}

#pragma mark -
#pragma mark view controller life cycle

- (void)viewWillAppear:(BOOL)animated
{
  [self subscribeToNotifications];
  
  // hide tabBar
  // remember previous tab bar state
  self.tabBarIsHidden = [[self.tabBarController tabBar] isHidden];
  if ( !self.tabBarIsHidden )
    [[self.tabBarController tabBar] setHidden:YES];
  
  if(self.wall != nil)
  { // check if we already have a wall, e.g. after return from some other controller
    // refresh UI
    if(self.FWConnection.requiresRequest)
    {
      [self showActivityIndicator];
    }
    
    [self refreshWall];
  }
  
  if(self.inputToolbar != nil)
  {
    [self.FWConnection refreshInputToolbarGeolocationIndicator:self.inputToolbar];
  }
  
  if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
  {
    tabsBackgroundVisible = YES; // this caused maps and photos buttons bar pulling up
    //higher and higher on picking image from gallery on iOS 6
  }
  
  [super viewWillAppear:animated];
}

-(void)subscribeToNotifications
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:self.hostReachable];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustWallToAuxiliaryToolbar:) name:kAuxiliaryToolbarToggledNotificationName object:nil];
  
  //for checking changes in notification state when returned from settings app
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refreshInputToolbarGeolocationIndicator)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self unsubscribeFromNotifications];
  
  // restore tab bar state
  [[self.tabBarController tabBar] setHidden:self.tabBarIsHidden];
  
  [self storeFBSharingCounts];
  
  [super viewWillDisappear:animated];
}


-(void)unsubscribeFromNotifications
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuxiliaryToolbarToggledNotificationName object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)storeFBSharingCounts
{
  [UD setObject:self.facebookLikesForPosts forKey:self.facebookLikesForPostsUDKey];
  [UD setObject:self.facebookLikedItems.allObjects forKey:self.facebookLikedItemsUDKey];
  [UD setObject:self.sharesCountForPosts forKey:self.sharesCountForPostsUDKey];
  
  dispatch_async(GCDBackgroundThread, ^{
    [UD synchronize];
  });
}

- (void)viewDidLoad
{
  self.navigationItem.title = self.pageTitle;
  [self.navigationController setNavigationBarHidden:NO animated:NO];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  
  self.view.backgroundColor = self.FWConnection.mFWColorOfBackground;
  
  onLoadingView = YES;
  tabsBackgroundVisible = YES;
  
  self.fwSettings.posts = [NSMutableArray array];
  
  canEdit = [self.FWConnection.mFWCanEdit isEqualToString:@"all"];
  CGFloat downloadIndicatorCenterY = (self.view.frame.size.height - (canEdit ? kInputToolbarInitialHeight : 0.0f)) / 2.0f;
  
  downloadIndicatorCenter =  (CGPoint){self.view.bounds.size.width  / 2.0f, downloadIndicatorCenterY};
  
  
  self.s_posts = [[UD objectForKey:@"s_posts_recent"] mutableCopy];
  
  self.firstPostID = @"0";
  self.lastPostID  = @"0";
  self.postID      = @"0";
  
  limit = 20;
  
  [self placeTabs];
  
  self.FWConnection.requiresRequest = YES;
  
  dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle:NSDateFormatterLongStyle];
  
  timeFormatter = [[NSDateFormatter alloc] init];
  [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
  
  self.hostReachable = [Reachability reachabilityWithHostName:[appIBuildAppHostName() stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  self.hostStatus = [self.hostReachable currentReachabilityStatus];

  [self setupAuthShare];
  
  [self restoreFBSharingCounts];
  
  // Moved here from viewWillAppear
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reachabilityChanged:)
                                               name:kReachabilityChangedNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleMessagePosting:)
                                               name:kFWMessagePostNotificationName
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleSharingFromPhotoBrowser:)
                                               name:kmFWPhotoBrowserSucceededSharingNotificationName
                                             object:nil];
  
//  With this thing wall loading initiated by reachability notification.
//  Normally we launch a module and immediately get the notif, that network is ok.
//  This notification starts loading the wall.
//  if([self checkReachabilityWithAlert:YES]) {
//    [self loadWall];
//  }
  
  [super viewDidLoad];
}

-(void)placeTabs
{
  self.tabsBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kButtonsBarHeight)];
  _tabsBackground.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
  [self.view addSubview:_tabsBackground];
  
  float separatorOriginX = self.view.frame.size.width / 2;
  float separatorOriginY = _tabsBackground.frame.origin.y + kSeparatorPaddingInButtonsBar;
  
  UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(separatorOriginX, separatorOriginY, kSeparatorWidth, kSeparatorHeight)];
  separator.backgroundColor = kSeparatorColor;
  [_tabsBackground addSubview:separator];
  
  self.mapButton = [self addButtonWithTitle:NSBundleLocalizedString(@"mFW_mapTabTitle", @"Map") icon:[UIImage imageNamed:resourceFromBundle(@"_mFW_map")] andOriginX:0.0f toTabsBackground:_tabsBackground];
  
  [self.mapButton addTarget:self action:@selector(mapButtonClicked) forControlEvents:UIControlEventTouchUpInside];
  
  self.photosButton = [self addButtonWithTitle:NSBundleLocalizedString(@"mFW_photosTabTitle", @"Photos") icon:[UIImage imageNamed:resourceFromBundle(@"_mFW_photos")] andOriginX:separatorOriginX + kSeparatorWidth toTabsBackground:_tabsBackground];
  
  [self.photosButton addTarget:self action:@selector(photosButtonClicked) forControlEvents:UIControlEventTouchUpInside];
  
  CGRect tabsBackgroundTopSpacerFrameUpperPart = CGRectMake(0.0f,
                                                            0.0f,
                                                            self.view.bounds.size.width,
                                                            tabsBackgroundSpacerHeight / 2);
  
  //Because on iOS 7+ we have already 0.5 pt semi-transparent thin spacer
  UIView *tabsBackgroundTopSpacerUpperPart = [[UIView alloc] initWithFrame:tabsBackgroundTopSpacerFrameUpperPart];
  tabsBackgroundTopSpacerUpperPart.backgroundColor = [tabsBackgroundBottomSpacerColor colorWithAlphaComponent:0.05f];
  [_tabsBackground addSubview:tabsBackgroundTopSpacerUpperPart];
  
  CGRect tabsBackgroundTopSpacerFrameLowerPart = CGRectMake(0.0f,
                                                            kHorizontalSpacerHeight / 2,
                                                            self.view.bounds.size.width,
                                                            tabsBackgroundSpacerHeight / 2);
  
  
  UIView *tabsBackgroundTopSpacerLowerPart = [[UIView alloc] initWithFrame:tabsBackgroundTopSpacerFrameLowerPart];
  tabsBackgroundTopSpacerLowerPart.backgroundColor = tabsBackgroundBottomSpacerColor;
  [_tabsBackground addSubview:tabsBackgroundTopSpacerLowerPart];
  
  CGRect tabsBackgroundBottomSpacerFrame = CGRectMake(0.0f,
                                                      _tabsBackground.frame.size.height,
                                                      self.view.bounds.size.width,
                                                      tabsBackgroundSpacerHeight);
  
  UIView *tabsBackgroundBottomSpacer = [[UIView alloc] initWithFrame:tabsBackgroundBottomSpacerFrame];
  tabsBackgroundBottomSpacer.backgroundColor = tabsBackgroundBottomSpacerColor;
  [_tabsBackground addSubview:tabsBackgroundBottomSpacer];
}

-(void)setupAuthShare
{
  // Moved here from viewWillAppear
  aSha = [auth_Share sharedInstance];
  aSha.delegate = self;
  aSha.viewController = self;
  aSha.messageProcessingBlock = nil;
}

-(void)restoreFBSharingCounts
{
  self.facebookLikesForPosts = [[UD objectForKey:self.facebookLikesForPostsUDKey] mutableCopy];
  self.facebookLikedItems = [[UD objectForKey:self.facebookLikedItemsUDKey] mutableCopy];
  self.sharesCountForPosts = [[UD objectForKey:self.sharesCountForPostsUDKey] mutableCopy];
  
  if(!self.facebookLikedItems){
    self.facebookLikedItems = [NSMutableSet set];
  }
  if(!self.facebookLikesForPosts){
    self.facebookLikesForPosts = [NSMutableDictionary dictionary];
  }
  if(!self.sharesCountForPosts){
    self.sharesCountForPosts = [NSMutableDictionary dictionary];
  }
}

#pragma mark -

- (UIButton *) addButtonWithTitle:(NSString *) title icon:(UIImage *)icon andOriginX:(CGFloat)originX toTabsBackground:(UIView *)tabsBackground
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  
  CGFloat buttonWidth = (tabsBackground.bounds.size.width) / 2 - kSeparatorWidth;
  button.frame = CGRectMake(originX, 0.0f, buttonWidth, kButtonsBarHeight);
  ////
  UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
  iconView.frame = CGRectMake(0, 0, icon.size.width, kIconWidthAndHeight);
  iconView.contentMode = UIViewContentModeScaleAspectFit;
  
  ////
  UILabel *buttonLabel = [[UILabel alloc] init];
  buttonLabel.text = title;
  buttonLabel.textColor = [UIColor whiteColor];
  buttonLabel.font = [UIFont boldSystemFontOfSize:14.0f];
  
  CGSize buttonLabelSize = [title sizeForFont:buttonLabel.font
                                    limitSize:CGSizeMake(self.view.bounds.size.width / 2, 500.0f)
                              nslineBreakMode:buttonLabel.lineBreakMode];
  
  buttonLabel.frame = CGRectMake(iconView.bounds.origin.x + iconView.bounds.size.width + kSpaceBetweenIconAndButtonName, 0, buttonLabelSize.width, buttonLabelSize.height);
  
  
  CGPoint centeredButtonLabelCenter = buttonLabel.center;
  centeredButtonLabelCenter.y = iconView.center.y;
  buttonLabel.center = centeredButtonLabelCenter;
  
  CGRect buttonContentFrame = CGRectZero;
  buttonContentFrame.origin.x = 0.0f;
  buttonContentFrame.origin.y = (tabsBackground.bounds.size.height - iconView.frame.size.height) / 2;
  buttonContentFrame.size.height = iconView.bounds.size.height;
  buttonContentFrame.size.width = buttonLabel.frame.origin.x + buttonLabel.bounds.size.width;
  
  
  UIView *buttonContentView = [[UIView alloc] initWithFrame:buttonContentFrame];
  [buttonContentView addSubview:iconView];
  buttonLabel.backgroundColor = [UIColor clearColor];
  [buttonContentView addSubview:buttonLabel];
  
  [button addSubview:buttonContentView];
  
  buttonContentView.center = CGPointMake(buttonWidth / 2, buttonContentView.center.y);
  
  buttonContentView.userInteractionEnabled = NO;
  
  [tabsBackground addSubview:button];
  
  return button;
}


#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  // loading new posts with cool new pull to refresh
  [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
  
  // loading older posts with old approach
  // 1.0f - overscroll threshold to trigger loading older posts
  if( scrollView.contentOffset.y + scrollView.bounds.size.height
     == scrollView.contentSize.height + scrollView.contentInset.bottom + 1.0f)
  {
    if(mayLoadOlderPosts){
      [self loadOlderPosts];
    }
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
  [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)loadNewerPosts
{
  self.postID = self.lastPostID;
  
  self.hostReachable = [Reachability reachabilityWithHostName:[appIBuildAppHostName() stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  self.hostStatus = [self.hostReachable currentReachabilityStatus];
  
  typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
  TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
  {
    if ( [[response objectForKey:@"posts"] count] > 0 )
    {
      NSMutableArray *mutableNewerPosts = [self mutableSortedPosts:[response objectForKey:@"posts"]];
      
      // LOAD NEWER POSTS
      //this little thingy prevents from duplicating post sent from bottom bar when we tired of waiting pulled to refresh
      if([mutableNewerPosts count] > 0)
      {
        for(NSDictionary *newPost in mutableNewerPosts)
        {
          NSString *newPostId = [newPost objectForKey:@"post_id"];
          for(NSDictionary *oldPost in self.fwSettings.posts)
          {
            NSString *oldPostId = [oldPost objectForKey:@"post_id"];
            if([oldPostId isEqualToString:newPostId]){
              goto postAlreadyExistsDoNotAddItOnceAgain;
            }
          }
          
          [self.fwSettings.posts insertObjects:mutableNewerPosts
                                     atIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, mutableNewerPosts.count)]];
          
          postAlreadyExistsDoNotAddItOnceAgain:;
        }
      }
      
      [UD setObject:[self.fwSettings.posts copy]
             forKey:@"s_posts_recent"];
      
      self.wallIsEmpty = NO;
      
      self.firstPostID = [[self.fwSettings.posts objectAtIndex:self.fwSettings.posts.count - 1] objectForKey:@"post_id"];
      self.lastPostID = [[self.fwSettings.posts objectAtIndex:0] objectForKey:@"post_id"];
    }
    
    NSRange newPostsRange = NSMakeRange(0, [[response objectForKey:@"posts"] count]);
    [self didLoadPostsForRange:newPostsRange strategy:LoadNewerPosts];
  };
  
  [self.FWConnection getMessagesWithParentID:@"0"
                                  andReplyID:@"0"
                                   andPostID:self.postID
                                       limit:kMessagesNoLimit //limit //
                                     success:^(NSData *result, NSDictionary *response) {
                                       completionBlock(result, response, nil);
                                     }
                                     failure:^(NSError *error)
                                     {
                                      completionBlock( nil, nil, error );
                                     }
   ];
}

- (void)loadOlderPosts
{
  [self showActivityIndicator];
  
  self.postID = self.firstPostID;
  
  if ( self.hostStatus == NotReachable )
  {
    [self didLoadPostsForRange:NSMakeRange(0, 0) strategy:LoadOlderPosts];
  }
  else
  {
    typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
    TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
    {
      NSRange olderPostsRange;
      
      if ( [[response objectForKey:@"posts"] count] < self.limit )
      {
        //mark that we've reached the bottom and there is no more need
        //to show download indicator when pulling the wall up to load older posts
        //(because there are no older posts)
        mayLoadOlderPosts = NO;
      }
      
      if ( [[response objectForKey:@"posts"] count] > 0 )
      {
        olderPostsRange = NSMakeRange(self.fwSettings.posts.count, [[response objectForKey:@"posts"] count]);
        
        NSMutableArray *mutableOlderPosts = [self mutableSortedPosts:[response objectForKey:@"posts"]];
        
        [self.fwSettings.posts addObjectsFromArray:mutableOlderPosts];
        
        [UD setObject:[self.fwSettings.posts copy]
               forKey:@"s_posts_recent"];
        
        self.wallIsEmpty = NO;
        
        self.firstPostID = [[self.fwSettings.posts objectAtIndex:self.fwSettings.posts.count - 1] objectForKey:@"post_id"];
        self.lastPostID = [[self.fwSettings.posts objectAtIndex:0] objectForKey:@"post_id"];
        
      } else {
        olderPostsRange = NSMakeRange(self.fwSettings.posts.count, 0);
      }
      
      [self didLoadPostsForRange:olderPostsRange strategy:LoadOlderPosts];
    };
    
    [self.FWConnection getMessagesWithParentID:@"0"
                                    andReplyID:@"0"
                                     andPostID:self.postID
                                         limit:-self.limit
                                       success:^(NSData *result, NSDictionary *response) {
                                         completionBlock(result, response, nil);
                                       }
                                       failure:^(NSError *error) {
                                         completionBlock( nil, nil, error );
                                       }];
  }
}

#pragma mark -
#pragma mark UINavigationCotrollerDelegate
- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

#pragma mark -
- (void)loadWall
{
  self.hostReachable = [Reachability reachabilityWithHostName:[appIBuildAppHostName() stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  self.hostStatus = [self.hostReachable currentReachabilityStatus];
  
  typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
  TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
  {
    self.FWConnection.afterPost = NO;
   
    NSUInteger postsCount = [[response objectForKey:@"posts"] count];
    
    if(postsCount < self.limit){
      mayLoadOlderPosts = NO;
    }
    
    if ( postsCount > 0 )
    {
      NSMutableArray *mutablePosts = [self mutableSortedPosts:[response objectForKey:@"posts"]];
      
      self.fwSettings.posts = mutablePosts;
      
      [UD setObject:[self.fwSettings.posts copy]
             forKey:@"s_posts_recent"];
      
      self.wallIsEmpty = NO;
      self.firstPostID = [[self.fwSettings.posts objectAtIndex:self.fwSettings.posts.count - 1] objectForKey:@"post_id"];
      self.lastPostID = [[self.fwSettings.posts objectAtIndex:0] objectForKey:@"post_id"];
      
      [self requestLikesAndShares];
    }
    else
    {
      if( ![self.fwSettings.posts count] && self.onLoadingView )
      {
        self.wallIsEmpty = YES;
      }
    }

    [self placeTheWall];
  };
  
  
  if (self.FWConnection.requiresRequest || self.FWConnection.afterPost)
  {
    [self showActivityIndicator];
    
    if ( self.hostStatus == NotReachable )
    {
      self.fwSettings.posts = [self.s_posts mutableCopy];
    }
    else
    {
      if ( self.FWConnection.requiresRequest || self.FWConnection.afterPost )
      {
        [self.FWConnection getMessagesWithParentID:@"0"
                                        andReplyID:@"0"
                                         andPostID:@"0"
                                             limit:self.limit
                                           success:^(NSData *result, NSDictionary *response) {
                                             completionBlock( result, response, nil );
                                           }
                                           failure:^(NSError *error) {
                                             completionBlock( nil, nil, error );
                                           }];
      }
    }
  }
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.fwSettings.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  mFWPostCell *cell = (mFWPostCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  NSDictionary *currentPost = [self.fwSettings.posts objectAtIndex:indexPath.row];
  
  UIView *postContentsSpacer;
  
  UILabel *postMessageLabel = nil;
  
  UIView  *commentsSpacer;
  
  UIView *socialButtonsPane;

  //Max width for text and image in post
  if ( cell == nil )
  {
    cell = [[mFWPostCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    cell.postContentsSpacer = [[UIView alloc] init];
    cell.postContentsSpacer.backgroundColor = kHorizontalSpacerColor;
    
    cell.postMessageLabel = [[UILabel alloc] init];
    cell.postMessageLabel.backgroundColor = [UIColor clearColor];
    cell.postMessageLabel.numberOfLines = 0;
    cell.postMessageLabel.font = [UIFont systemFontOfSize:kPostTextSize];
    cell.postMessageLabel.textColor = kPostTextColor;
    
    
    cell.attachedThumbnailImageViewContainer = [[UIView alloc] init];
    cell.attachedThumbnailImageViewContainer.backgroundColor = [UIColor whiteColor];
    cell.attachedThumbnailImageViewContainer.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
    cell.attachedThumbnailImageViewContainer.layer.shadowColor = [[UIColor blackColor] CGColor];
    cell.attachedThumbnailImageViewContainer.layer.shadowOpacity = 0.3f;
    cell.attachedThumbnailImageViewContainer.layer.shadowRadius = 2.0f;
    cell.attachedThumbnailImageViewContainer.userInteractionEnabled = YES;
      
    cell.attachedThumbnailImageView = [[UIImageView alloc] init];
      
    cell.attachedThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.attachedThumbnailImageView.clipsToBounds = YES;
      
    [cell.attachedThumbnailImageViewContainer addSubview:cell.attachedThumbnailImageView];
      
    UITapGestureRecognizer *avatarImageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
    avatarImageTap.delegate = self;
    [cell.avatarImageView addGestureRecognizer:avatarImageTap];
      
    
    cell.commentsSpacer = [[UIView alloc] init];
    cell.commentsSpacer.backgroundColor = kHorizontalSpacerColor;
    
    CGRect socialButtonsPaneFrame = (CGRect){kMarginFromScreenEdges, 0.0f, kPostCellWidth - 1.0f, kSocialButtonHeight};
    cell.socialButtonsPane = [[UIView alloc] initWithFrame:socialButtonsPaneFrame];
    
    CGFloat socialButtonWidth = (NSInteger)((kPostCellWidth - 1.0f) / 3);
    
    CGRect commentsButtonFrame = kSocialButtonFrameWithOriginX(0.0f);
    CGRect likesButtonFrame = kSocialButtonFrameWithOriginX(socialButtonWidth);
    CGRect sharesButtonFrame = kSocialButtonFrameWithOriginX(2 * socialButtonWidth);
    
    cell.commentsButton = [self addSocialButtonWithFrame:commentsButtonFrame andImageNamed:resourceFromBundle(@"mFW_comments") toPostCell:cell];
    
    UIView *likesAndSharesPlaceholder = [[UIView alloc] initWithFrame:(CGRect){socialButtonWidth, 0.0f, kPostCellWidth - socialButtonWidth, kSocialButtonHeight}];
    likesAndSharesPlaceholder.userInteractionEnabled = YES;
    //do not go to comments on tap on the rest of social pane if neither likes nor shares button present
    UITapGestureRecognizer *doNothingRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:0 action:0];
    [likesAndSharesPlaceholder addGestureRecognizer:doNothingRecognizer];
    [cell.socialButtonsPane addSubview:likesAndSharesPlaceholder];
    
    cell.likesButton = [self addSocialButtonWithFrame:likesButtonFrame andImageNamed:resourceFromBundle(@"mFW_like_off") toPostCell:cell];
    
    cell.likesButton.socialActionsCount = 0;
    cell.likesButton.socialImageView.highlightedImage = [UIImage imageNamed:resourceFromBundle(@"mFW_like_on")];
    cell.likesButton.socialImageView.highlighted = NO;
      
      
    UITapGestureRecognizer *likesTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(likesButtonTapped:)];
    [cell.likesButton addGestureRecognizer:likesTapRecognizer];
    
    cell.sharesButton = [self addSocialButtonWithFrame1:sharesButtonFrame andImageNamed:resourceFromBundle(@"mFW_more") toPostCell:cell];
    cell.sharesButton.socialActionsCount = 0;
    
    UITapGestureRecognizer *sharesTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sharesButtonTapped:)];
    [cell.sharesButton addGestureRecognizer:sharesTapRecognizer];
    
    cell.backgroundRoundedRectangle = [[UIView alloc] init];
    
    [cell.contentView addSubview:cell.postMessageLabel];
    [cell.contentView addSubview:cell.attachedThumbnailImageViewContainer];
    [cell.contentView addSubview:cell.commentsSpacer];
    [cell.contentView addSubview:cell.socialButtonsPane];
    
    cell.backgroundRoundedRectangle.layer.cornerRadius = kBackgroundRoundedRectangleCornerRadius;
    cell.backgroundRoundedRectangle.layer.masksToBounds = YES;
    cell.backgroundRoundedRectangle.userInteractionEnabled = YES;
    
    [cell.contentView addSubview:cell.backgroundRoundedRectangle];
    [cell.contentView sendSubviewToBack:cell.backgroundRoundedRectangle];
    
    cell.userInteractionEnabled = YES;
  }
  
  UIColor *backgroundColor;
  
  CGFloat maxPostContentWidth = cell.frame.size.width - 2 * kPostContentOffsetX;
  
  if ( ( [[currentPost objectForKey:@"account_type"] isEqual:aSha.user.type] ) &&
      ( [[currentPost objectForKey:@"account_id"]   isEqual:aSha.user.ID] ) )
  {
    backgroundColor = kOtherPostBackgroundColor;
  } else {
    backgroundColor = kOtherPostBackgroundColor;
  }
  
  postContentsSpacer = cell.postContentsSpacer;
  postMessageLabel = cell.postMessageLabel;
  commentsSpacer = cell.commentsSpacer;
  socialButtonsPane = cell.socialButtonsPane;
  
  NSString *avatarUrl = [currentPost objectForKey:@"user_avatar"];
    
  //reset image. Otherwise reusable stuff goes messy and we have image from formerly used cell on newly appeared cell
  cell.avatarImageView.image = [UIImage imageNamed:resourceFromBundle(@"_mFW_big_ava")];
    
  if ( [avatarUrl length] )
  {
    [cell setAvatarImageForURL:avatarUrl withPlaceholderImage:[UIImage imageNamed:resourceFromBundle(@"_mFW_big_ava")]];
  }
  
  NSDictionary *post = currentPost;
  
  
  NSString *dateString = [post objectForKey:@"create"];
  double dateDouble = dateString.doubleValue/1000;
  
  NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:dateDouble];
  
  CGFloat horizontalSpacerX = kMarginFromScreenEdges;
  CGFloat horizontalSpacerY = kAvatarPaddingTop + kAvatarImageViewWidthAndHeight + kAvatarPaddingBottom;
  CGFloat horizontalSpacerWidth = cell.frame.size.width - 2 * kMarginFromScreenEdges;
  
  CGRect postContentsSpacerFrame = CGRectMake(horizontalSpacerX,
                                              horizontalSpacerY,
                                              horizontalSpacerWidth,
                                              kHorizontalSpacerHeight);
  
  
  postContentsSpacer.frame = postContentsSpacerFrame;
  
  UITapGestureRecognizer *imageViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
  
  imageViewTap.delegate = self;
  [cell.imageView addGestureRecognizer:imageViewTap];
  
  cell.userNameLabel.text = [currentPost objectForKey:@"user_name"];
  UITapGestureRecognizer *userNameLabelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
  
  userNameLabelTap.delegate = self;
  [cell.userNameLabel addGestureRecognizer:userNameLabelTap];
  
  cell.postDateLabel.lineBreakMode = NSLineBreakByCharWrapping;
  
  NSString *dateDiff = [mFWSettings dateDiffForDate:postDate];
  cell.postDateLabel.text = [dateDiff isEqualToString:@"(null)" ] ? NSBundleLocalizedString(@"mFW_dateDiffJustNow", @"Just now") : dateDiff;
  
  
  NSString *messageText = [currentPost objectForKey:@"text"];
  
  if ( [messageText length])
  {
    [postMessageLabel setHidden:NO];
    
    postMessageLabel.text = ( [messageText length] ) ? messageText : @" ";
    
    CGSize labelSize = [postMessageLabel.text sizeForFont:postMessageLabel.font
                                                limitSize:CGSizeMake(maxPostContentWidth, 500.0f)
                                          nslineBreakMode:postMessageLabel.lineBreakMode];
    
    //What is kPostMessagePullupOffset? Text in Label does not touch with its highest points the top line of the Rect.
    //So we have to pull the rect with text slightly up.
    postMessageLabel.frame = CGRectMake(kPostContentOffsetX,
                                        postContentsSpacer.frame.origin.y + /* kHorizontalSpacerHeight  */kSpaceBetweenHorizontalSpacerAndPostMessage - kPostMessagePullupOffset,
                                        maxPostContentWidth, (NSUInteger)labelSize.height);
  } else {
    [postMessageLabel setHidden:YES];
     postMessageLabel.text = nil;
  }
  
  if ( indexPath.row >= [self.fwSettings.posts count] )
    return cell;
  
  NSArray *thumbs = [currentPost objectForKey:@"thumbs"];
  
  if ( [thumbs count] )
  {
      //reset image. Otherwise reusable stuff goes messy and we have image from formerly used cell on newly appeared cell
      cell.attachedThumbnailImageView.image =  self.placeholderImage;
      
    cell.likesButton.hidden = NO;
    cell.sharesButton.hidden = NO;
    
    [cell.attachedThumbnailImageViewContainer setHidden:NO];
    
    CGFloat attachedImageViewY;
    
    if(postMessageLabel != nil && !postMessageLabel.hidden){
      attachedImageViewY = postMessageLabel.frame.origin.y + postMessageLabel.frame.size.height + kSpaceBetweenPostTextAndAttachedImage;
    } else {
      attachedImageViewY = postContentsSpacer.frame.origin.y + postContentsSpacer.frame.size.height + kSpaceBetweenPostTextAndAttachedImage;
    }
      
    cell.attachedThumbnailImageViewContainer.frame = CGRectMake(kPostContentOffsetX, attachedImageViewY, maxPostContentWidth, kAttachedImageHeight);
    
    
    NSString *imageURL = [[post objectForKey:@"images"] objectAtIndex:0];
    
    NSNumber *likesCount = [self.facebookLikesForPosts objectForKey:imageURL];
    
    if(likesCount){
      cell.likesButton.socialActionsCount = [likesCount integerValue];
    }
    
    NSNumber *sharesQty = [self.sharesCountForPosts objectForKey:imageURL];
    
    if (sharesQty && cell.sharesButton) {
      cell.sharesButton.socialActionsCount = [sharesQty integerValue];
    }
    
    if([self.facebookLikedItems containsObject:imageURL]){
      cell.likesButton.socialImageView.highlighted = YES;
      cell.likesButton.userInteractionEnabled = NO;
    } else {
      cell.likesButton.socialImageView.highlighted = NO;
      cell.likesButton.userInteractionEnabled = YES;
    }
      
    CGRect attachedThumbnailImageViewFrame = CGRectMake(kImageBorderWidth,
                       kImageBorderWidth,
                       maxPostContentWidth - 2 * kImageBorderWidth,
                       kAttachedImageHeight - 2 * kImageBorderWidth);
      
      cell.attachedThumbnailImageView.frame = attachedThumbnailImageViewFrame;
      
    [cell setAttachedImageThumbnailForURL:thumbs[0] withPlaceholderImage:self.placeholderImage];

    UITapGestureRecognizer *attachedImageTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(showAttachedImage:)];
    attachedImageTap.delegate = self;
    [cell.attachedThumbnailImageViewContainer addGestureRecognizer:attachedImageTap];
    
  } else {
    [cell.attachedThumbnailImageViewContainer setHidden:YES];
    cell.likesButton.hidden = YES;
    cell.sharesButton.hidden = YES;
  }
  
  CGFloat commentsSpacerY;
  
  if(cell.attachedThumbnailImageViewContainer != nil && !cell.attachedThumbnailImageViewContainer.hidden){
    commentsSpacerY = cell.attachedThumbnailImageViewContainer.frame.origin.y + cell.attachedThumbnailImageViewContainer.frame.size.height + kSpaceBetweenImageAndCommentsSpacer;
  } else if (postMessageLabel != nil && !postMessageLabel.hidden){
    commentsSpacerY = postMessageLabel.frame.origin.y + postMessageLabel.frame.size.height + kSpaceBetweenImageAndCommentsSpacer;
  } else {
    commentsSpacerY = postContentsSpacer.frame.origin.y + postContentsSpacer.frame.size.height + kSpaceBetweenImageAndCommentsSpacer;
  }

  CGRect commentsSpacerFrame = CGRectMake(postContentsSpacerFrame.origin.x, commentsSpacerY, postContentsSpacerFrame.size.width - kBackgroundRoundedRectangleBorderWidth, kHorizontalSpacerHeight);
  commentsSpacer.frame = commentsSpacerFrame;
  
  NSString *totalComments = [currentPost objectForKey:@"total_comments"];
  
  CGRect socialButtonsPaneFrame = socialButtonsPane.frame;
  socialButtonsPaneFrame.origin.y = commentsSpacerFrame.origin.y + kHorizontalSpacerHeight;
  socialButtonsPane.frame = socialButtonsPaneFrame;
  
  if(totalComments){
    cell.commentsButton.socialActionsCount = [totalComments intValue];
    
    UITapGestureRecognizer *commentsTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentsButtonTapped:)];
    [cell.commentsButton addGestureRecognizer:commentsTapRecognizer];
    
    [cell addGestureRecognizer:commentsTapRecognizer];
  }
  
  CGFloat backgroundHeight = [self calculateCellHeightForIndexPath:indexPath] - kSpaceBetweenPostCells;
  CGRect backroundRoundedRectangleFrame = CGRectMake(kMarginFromScreenEdges - kBackgroundRoundedRectangleBorderWidth, 0.0f, cell.frame.size.width - 2 * kPostContentsPaddingLeft + kBackgroundRoundedRectangleBorderWidth, // Why 2 lefts? Right padding is same, so there is no dedicated variable for it
                                                     backgroundHeight);
  
  cell.backgroundRoundedRectangle.backgroundColor = backgroundColor;
  cell.backgroundRoundedRectangle.frame = backroundRoundedRectangleFrame;
  
  cell.backgroundRoundedRectangle.layer.borderWidth = kBackgroundRoundedRectangleBorderWidth;
  cell.backgroundRoundedRectangle.layer.borderColor = kBackgroundRoundedRectangleBorderColor;
  
  return cell;
}


- (CGFloat) calculateCellHeightForIndexPath:(NSIndexPath *) indexPath
{
  CGFloat height = kAvatarPaddingTop + kAvatarImageViewWidthAndHeight + kAvatarPaddingBottom + kHorizontalSpacerHeight + kSpaceBetweenHorizontalSpacerAndPostMessage;
  
  NSDictionary *currentPost = [self.fwSettings.posts objectAtIndex:indexPath.row];
  NSString *messageText = [currentPost objectForKey:@"text"];
  
  BOOL hasText = messageText.length > 0;
  if(hasText){
    UILabel *messageLabel = [[UILabel alloc] init];
    
    messageLabel.numberOfLines = 0;
    messageLabel.font = [UIFont systemFontOfSize:kPostTextSize];
    messageLabel.text = messageText;
    
    CGSize labelSize = [messageLabel.text sizeForFont:messageLabel.font
                                            limitSize:CGSizeMake(self.view.bounds.size.width - 2 * kPostContentOffsetX, 500.0f)
                                      nslineBreakMode:messageLabel.lineBreakMode];
    height += labelSize.height;
    
  }
  
  if([[currentPost objectForKey:@"thumbs"] count]){
    if(hasText){
      height += kSpaceBetweenPostTextAndAttachedImage;
    } else {
      height += kCommentsLabelTextPullupOffset;
    }
    height += kAttachedImageHeight;
  }
  
  height += kSpaceBetweenImageAndCommentsSpacer + kHorizontalSpacerHeight + kSocialButtonHeight + kCommentsLabelTextPullupOffset + kPostMessagePullupOffset - 1.0f;
  
  return height - 1.0f;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (CGFloat)tableView:textLabeltableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return [self calculateCellHeightForIndexPath:indexPath];
}


#pragma mark - Actions
- (void)showAttachedImage:(UIGestureRecognizer *)recognizer
{
  NSIndexPath *swipedIndexPath = [self.wall indexPathForRowAtPoint:[recognizer locationInView:self.wall]];
  self.FWConnection.activeCell = swipedIndexPath;
  
  NSURL *photoURL = [NSURL URLWithString:[[[[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"images"] objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  const char *key = [kAttachedPostIdKey UTF8String];
  NSString *postId = self.fwSettings.posts[swipedIndexPath.row][@"post_id"];
  objc_setAssociatedObject(photoURL, key, postId, OBJC_ASSOCIATION_RETAIN);
  
  NSMutableArray *photos = [[NSMutableArray alloc] init];
  MWPhoto *photo = [MWPhoto photoWithURL:photoURL];
  photo.caption = [NSBundleLocalizedString(@"mFW_postedByPhotoCaption", @"Posted by ") stringByAppendingString:[[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"user_name"]];
  photo.description = [[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"text"];
  
  [photos addObject:photo];
  
  self.fwSettings.photos = photos;
  
  mFWPhotoBrowser *browser = [[mFWPhotoBrowser alloc] initWithDelegate:self];
  browser.displayActionButton = YES;
  browser.bSavePicture        = YES;
  browser.leftBarButtonCaption = NSBundleLocalizedString(@"mFW_backToWallButtonTitle", @"Wall");
  [browser setInitialPageIndex:0];
  [self.navigationController pushViewController:browser animated:YES];
}

- (void)showUserProfile:(UIGestureRecognizer *)recognizer
{
  if( self.hostStatus == NotReachable )
    return;
  
  NSIndexPath *swipedIndexPath = [self.wall indexPathForRowAtPoint:[recognizer locationInView:self.wall]];
  
  mFWProfile *mFWProfileView = [[mFWProfile alloc] init];
  
  mFWProfileView.avatarURL   = [[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"user_avatar"];
  mFWProfileView.userName    = [[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"user_name"];
  mFWProfileView.accountType = [[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"account_type"];
  mFWProfileView.accountID   = [[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"account_id"];
  
  [self showActivityIndicator];
  
  [self.FWConnection getProfileInfoForUserWithAccountID:mFWProfileView.accountID
                                         andAccountType:(mFWProfileView.accountType.length ? mFWProfileView.accountType : @"ibuildapp")
                                                success:^(NSData *result, NSDictionary *response) {
                                                  self.view.userInteractionEnabled = YES;
                                                  self.navigationController.navigationBar.userInteractionEnabled = YES;
                                                  [self.FWConnection hideIndicator];
                                                  
                                                  mFWProfileView.dateString = [[response objectForKey:@"data"] objectForKey:@"last_message"];
                                                  mFWProfileView.pCountText = [[response objectForKey:@"data"] objectForKey:@"total_posts"];
                                                  mFWProfileView.cCountText = [[response objectForKey:@"data"] objectForKey:@"total_comments"];
                                                  
                                                  [self.navigationController pushViewController:mFWProfileView animated:YES];
                                                }
                                                failure:^(NSError *error) {
                                                  self.view.userInteractionEnabled = YES;
                                                  self.navigationController.navigationBar.userInteractionEnabled = YES;
                                                  [self.FWConnection hideIndicator];
                                                }];
}

- (void)goToPost
{
  authenticationRequestSource = PostScreen;
  [self authenticateWithAsha];
}

- (void)placeTheWall
{
  if(self.FWConnection.requiresRequest) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.wall reloadData];
    });
  }
  
  [self.FWConnection hideIndicator];
  self.view.userInteractionEnabled = YES;
  self.navigationController.navigationBar.userInteractionEnabled = YES;
  
  self.mapButton.enabled        = !self.wallIsEmpty;
  self.photosButton.enabled     = !self.wallIsEmpty;
  
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.view.autoresizesSubviews = YES;
  
  if ( self.FWConnection.requiresRequest )
  {
    self.pageContent = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                 kButtonsBarHeight +kHorizontalSpacerHeight,
                                                                 self.view.frame.size.width,
                                                                 self.view.frame.size.height - kButtonsBarHeight)];
    self.pageContent.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.pageContent.backgroundColor = self.FWConnection.mFWColorOfBackground;
    [self.view addSubview:self.pageContent];
  }
  
  self.FWConnection.requiresRequest = YES;
  
  self.hostReachable = [Reachability reachabilityWithHostName:[appIBuildAppHostName() stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  self.hostStatus = [self.hostReachable currentReachabilityStatus];

   // in case we already have a wall an just refreshing its content we do not remove it (and whatever is on the superview) from superview
  if(onLoadingView)
  {
    if ( self.FWConnection.requiresRequest )
    {
      for ( UIView *view in self.pageContent.subviews )
      {
        [view removeFromSuperview];
      }
    }
  }
  
  typedef void (^TFinalCompletionBlock)(void);
  TFinalCompletionBlock finalCompletionBlock = ^void(void)
  {
    if ( self.FWConnection.requiresRequest )
    {
      if(onLoadingView) // in case we already have a wall and just refreshing it, we do not construct it once again
      {
        [self setupWall];
        [self.pageContent addSubview:self.wall];
        
        if (canEdit)
        {
          [self inputToolbarInit];
        }
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.wall reloadData];
      });
    }
    
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if ( self.wallIsEmpty )
    {
      [self showNoMessagesLabel];
    } else {
      [self hideNoMessagesLabel];
    }
    [self.FWConnection hideIndicator];
    
    onLoadingView = NO;
    wallCreated = YES;
  };
  
  
  if ( self.FWConnection.requiresRequest )
  {
    [self showActivityIndicator];
    
    if ( hostStatus == NotReachable )
    {
      self.fwSettings.posts = [self.s_posts mutableCopy];
    }
    else
    {
      {
        if ( [self.fwSettings.posts count] > 0 )
        {
          wallIsEmpty = NO;
          
          self.firstPostID = [[self.fwSettings.posts objectAtIndex:self.fwSettings.posts.count - 1] objectForKey:@"post_id"];
          self.lastPostID = [[self.fwSettings.posts objectAtIndex:0] objectForKey:@"post_id"];
        } else {
          if ( ![self.fwSettings.posts count] &&
              self.onLoadingView)
          {
            self.wallIsEmpty = YES;
          }
        }
        finalCompletionBlock();
      }
    }
  }
}

- (void)mapButtonClicked
{
  onLoadingView = NO;
  
  mFWMap *fwMap = [[mFWMap alloc] init];

  if ( self.fwSettings.posts.count )
  {
    NSMutableDictionary  *pin = [[NSMutableDictionary alloc] init];
    
    for ( int i = 0; i < self.fwSettings.posts.count; i++ )
    {
      NSDictionary *currentPost = [self.fwSettings.posts objectAtIndex:i];
      
      if ( ![[currentPost objectForKey:@"latitude"] isEqualToString:@"1000"] )
      {
        [pin setObject:[currentPost objectForKey:@"user_name"] forKey:@"title"];
        [pin setObject:[currentPost objectForKey:@"text"]      forKey:@"subtitle"];
        [pin setObject:[currentPost objectForKey:@"latitude"]  forKey:@"latitude"];
        [pin setObject:[currentPost objectForKey:@"longitude"] forKey:@"longitude"];
        
        NSString *aURL = nil;
        if ( [[currentPost objectForKey:@"account_type"] isEqualToString:@"facebook"] )
        {
          aURL = [NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@", [currentPost objectForKey:@"account_id"]];
        }
        if ( [[currentPost objectForKey:@"account_type"] isEqualToString:@"twitter"] )
        {
          aURL = [NSString stringWithFormat:@"https://twitter.com/intent/user?user_id=%@", [currentPost objectForKey:@"account_id"]];
        }
        if ( ( [[currentPost objectForKey:@"account_type"] isEqualToString:@"ibuildapp"]) ||
            ( ![[currentPost objectForKey:@"account_type"] length] ) )
        {
          aURL = [NSString stringWithFormat:@"http://%@/members/%@", appIBuildAppHostName(), [currentPost objectForKey:@"account_id"]];
        }
        
        if( !aURL.length )
          aURL = @"";
        
        [pin setObject:aURL forKey:@"description"];
        [fwMap.mapPoints addObject:[pin copy]];
        [pin removeAllObjects];
      }
    }
  }
  fwMap.title = NSBundleLocalizedString(@"mFW_mapTabTitle", @"Map");
  [self.navigationController pushViewController:fwMap animated:YES];
}

- (void)photosButtonClicked
{
  mFWPhotosViewController *phohosVC = [[mFWPhotosViewController alloc] init];
  phohosVC.FWConnection = self.FWConnection;
  phohosVC.fwSettings = self.fwSettings;

  phohosVC.title = NSBundleLocalizedString(@"mFW_photosTabTitle", @"Photos");
  [self.navigationController pushViewController:phohosVC animated:YES];
}

- (void)sendMessageButtonClicked
{
  [self goToPost];
}

#pragma mark -
#pragma mark NRGridViewDataSource
- (NSInteger)gridView:(NRGridView *)gridView numberOfItemsInSection:(NSInteger)section
{
  return self.fwSettings.imageLinks.count;
}

- (NRGridViewCell *)gridView:(NRGridView *)gridView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *MyCellIdentifier = @"Cell";
  
  NRGridViewCell *cell = [gridView dequeueReusableCellWithIdentifier:MyCellIdentifier];
  
  if ( cell == nil )
  {
    cell = [[NRGridViewCell alloc] initWithReuseIdentifier:MyCellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
  }
  cell.imageView.frame = CGRectMake(10, 10,
                                    self.gallery.cellSize.width  - 20,
                                    self.gallery.cellSize.height - 20 );
  
  SDWebImageSuccessBlock fadeInBlock = ^(UIImage *image, BOOL cached)
  {
    cell.imageView.alpha = 0.0f;
    [UIView animateWithDuration:kFadeInDuration animations:^{
      cell.imageView.alpha = 1.0f;
    }];
  };
  
  [cell.imageView setImageWithURL:[NSURL URLWithString:[[[self.fwSettings.imageLinks objectAtIndex:indexPath.itemIndex] objectForKey:@"thumb"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                 placeholderImage:cell.imageView.image ? cell.imageView.image : self.placeholderImage
                          success:fadeInBlock
                          failure:nil];
  
  
  return cell;
}

#pragma mark -
#pragma mark NRGridViewDelegate
- (void)gridView:(NRGridView *)gridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
  [self.gallery deselectCellAtIndexPath:indexPath animated:NO];
  
  self.FWConnection.activeImage = indexPath;
  
  MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
  browser.displayActionButton  = YES;
  browser.bSavePicture         = YES;
  browser.leftBarButtonCaption = NSBundleLocalizedString(@"mFW_backToPhotosButtonTitle", @"Photos");
  [browser setInitialPageIndex:indexPath.itemIndex];
  [self.navigationController pushViewController:browser animated:YES];
}

- (void)gridView:(NRGridView *)gridView didLongPressCellAtIndexPath:(NSIndexPath *)indexPath
{
  [self.gallery deselectCellAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
  if (self.fwSettings.photos)
    return self.fwSettings.photos.count;
  else
    return 0;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
  if ( self.fwSettings.photos && index < self.fwSettings.photos.count )
    return [self.fwSettings.photos objectAtIndex:index];
  return nil;
}

#pragma mark -
#pragma mark Reachability
- (void)reachabilityChanged: (NSNotification* )notification
{
  if ( [[notification object] currentReachabilityStatus] == NotReachable )
  {
    self.reachable = NO;
  } else {
    self.reachable = YES;
    
    if(!wallCreated){
      [self loadWall];
    }
  }
  self.hostStatus = self.reachable;
}

- (BOOL)checkReachabilityWithAlert:(BOOL)showAlert
{
  // we don't need to get actual reachability status! because hostStatus will
  // change every time when we get reachabilityChanged notification!

  if (self.hostStatus == NotReachable )
  {
    
    if (showAlert)
    {
      UIAlertView *msg = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"general_cellularDataTurnedOff",@"Cellular Data is Turned off")
                                                     message:NSLocalizedString(@"general_cellularDataTurnOnMessage",@"Turn on cellular data or use Wi-Fi to access data")
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"general_defaultButtonTitleOK",@"OK")
                                           otherButtonTitles:nil];
      [msg show];
    }
    
    return NO;
  }
  else
    return YES;
  
}

#pragma mark -
#pragma mark autorotate handlers
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

-(BOOL)shouldAutorotate
{
  return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
  self.reloading = YES;
  [self refreshWall];
}
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
  return self.reloading; // should return if data source model is reloading
}
- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
  return [NSDate date]; // should return date data source was last changed
}


- (void)insertRowsFromRange:(NSRange)range withAnimation:(UITableViewRowAnimation)animation{
  NSMutableArray *indexPathsToInsert = [NSMutableArray array];
  
  NSInteger startRow = range.location;
  NSInteger length = range.length;
  NSInteger finishRow = startRow + length;
  
  for(NSInteger index = startRow; index < finishRow; index++){
    [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:index inSection:0]];
  }
  [self.wall beginUpdates];
  [self.wall insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:animation];
  [self.wall endUpdates];
  
  if(shouldScrollToTop){
    [self.wall setContentOffset:(CGPoint){self.wall.contentOffset.x, -kSpaceBetweenPostCells} animated:YES];
    shouldScrollToTop = NO;
  }
}

- (void)didLoadPostsForRange:(NSRange)range
                     strategy:(PostsLoadingStrategy)strategy
{
  [self.FWConnection hideIndicator];
  
  if(self.reloading) { // we were uptading with EGO pull to refresh
    self.reloading = NO;
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.wall];
  }
  
  self.FWConnection.requiresRequest = NO;
  self.view.userInteractionEnabled = YES;
  self.navigationController.navigationBar.userInteractionEnabled = YES;
  
  switch(strategy){
    case LoadOlderPosts:
    {
      if(range.length){
        [self insertRowsFromRange:range withAnimation:UITableViewRowAnimationNone];
      }
    }
    break;
      
    case LoadNewerPosts:
    {
      if(range.length){
        [self insertRowsFromRange:range withAnimation:UITableViewRowAnimationAutomatic];
      }
    }
    break;
      
    case ReloadExistingPosts:{
      if(rowsToDelete){ //how many post were deleted on server

        NSMutableArray *indexPathsToDelete = [NSMutableArray array];
        
        for(NSInteger index = 0; index < rowsToDelete; index++){
          [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
        
        [self.wall beginUpdates];
        [self.wall deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.wall endUpdates];
        
        rowsToDelete = 0;
      }
      
      if(range.length)
      {
        [self insertRowsFromRange:range
                    withAnimation:UITableViewRowAnimationNone];
      }
      
      [self updateVisibleCells];
    }
    break;
      
    case LoadPostsAtStart:
    default:
      [self.wall reloadData];
      break;
  }
  
  if([self.fwSettings.posts count]){
    
    NSArray *postsToUpdateLikesAndShares = [self.fwSettings.posts subarrayWithRange:range];
    [self fillLikesAndSharesForPosts:postsToUpdateLikesAndShares];
    
    [self hideNoMessagesLabel];
    if(!self.mapButton.enabled){
      self.mapButton.enabled = YES;
    }
    if(!self.photosButton.enabled){
      self.photosButton.enabled = YES;
    }
  } else {
    [self showNoMessagesLabel];
  }
}


- (void)setupWall
{
  CGFloat wallHeight = self.pageContent.frame.size.height;
  
  self.wall = [[UITableView alloc] initWithFrame:CGRectMake(0.0f,
                                                             0.0f,
                                                             self.pageContent.frame.size.width,
                                                             wallHeight)
                                            style:UITableViewStylePlain];
  
  if(canEdit){
    UIEdgeInsets pulledUpInsets = self.wall.contentInset;
    pulledUpInsets.bottom = kInputToolbarInitialHeight;
    pulledUpInsets.top = kSpaceBetweenPostCells;
    
    self.wall.contentInset = pulledUpInsets;
  }
  
  self.wall.showsHorizontalScrollIndicator = NO;
  self.wall.showsVerticalScrollIndicator = NO;
  
  self.wall.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.wall.backgroundColor = [UIColor clearColor];
  self.wall.dataSource = self;
  self.wall.delegate = self;
  self.wall.separatorStyle = UITableViewCellSeparatorStyleNone;
  
  // EGORefreshTableHeaderView initialization
  self.reloading = NO;
  self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(kMarginFromScreenEdges,
                                                                                        0.0f - kRefreshHeaderViewHeight - kSpaceBetweenPostCells,
                                                                                        self.wall.bounds.size.width - 2 * kMarginFromScreenEdges,
                                                                                        kRefreshHeaderViewHeight)];
  self.refreshHeaderView.layer.cornerRadius = kBackgroundRoundedRectangleCornerRadius;
  
  self.refreshHeaderView.delegate = self;
  
  [self.wall addSubview:self.refreshHeaderView];
  //  update the last update date
  [self.refreshHeaderView refreshLastUpdatedDate];
  
  UITapGestureRecognizer *keyboardHider = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  [self.wall addGestureRecognizer:keyboardHider];
}

#pragma mark - inputToolbar

- (void)inputToolbarInit
{
  if (self.inputToolbar)
  {
    [self.inputToolbar.textView resignFirstResponder];
    self.inputToolbar.inputToolbarDelegate = nil;
    [self.inputToolbar removeFromSuperview];
    self.inputToolbar = nil;
  }
  
  CGRect inputToolbarFrame = CGRectMake(0.0f, self.view.frame.size.height - kInputToolbarInitialHeight, self.view.frame.size.width,  kInputToolbarInitialHeight);
  
  self.inputToolbar = [[mFWInputToolbar alloc] initWithFrame:inputToolbarFrame andManagingController:self];
  self.inputToolbar.backgroundColor = kInputToolBarColor;
  
  self.inputToolbar.inputToolbarDelegate = self;
  
  [self.FWConnection refreshInputToolbarGeolocationIndicator:self.inputToolbar];
  
  self.inputToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  
  [self.view addSubview:self.inputToolbar];
}

- (void)handleMessagePosting:(NSNotification *)notification
{
  if([notification.name isEqualToString:kFWMessagePostNotificationName]){
    
    self.FWConnection.requiresRequest = NO;
    
    if ( aSha.user.authentificatedWith != auth_ShareServiceTypeNone ) {
      if(authenticationRequestSource == PostScreen){
        authenticationRequestSource = None;
        [self performSelector:@selector(goToPost) withObject:nil afterDelay:0.8f];
        return;
      }
    }
    
    enteredPostText = [[notification userInfo] objectForKey:kFWMessagePostTextKey];
    messagePostImages = [[notification userInfo] objectForKey:kFWMessagePostImagesKey];
    
    messagePostImages = [messagePostImages isEqual:[NSNull null]] ? nil : messagePostImages;
    enteredPostText = [enteredPostText isEqual:[NSNull null]] ? nil : enteredPostText;
    
    if([self.view viewWithTag:kInputToolbarMaskViewTag])
    {
      [[self.view viewWithTag:kInputToolbarMaskViewTag] removeFromSuperview];
    }
    
    if (enteredPostText.length || messagePostImages.count)
    {
      if ( aSha.user.authentificatedWith != auth_ShareServiceTypeNone )
      {
        if(authenticationRequestSource == BottomBar){
          authenticationRequestSource = None;
        }
        
        [self showActivityIndicator];
        
        [self performSelector:@selector(postMessage) withObject:nil afterDelay:0.3f];
      } else {
        
        if(!tabsBackgroundVisible){
          [self toggleTabsBackgroundVisibility];
          tabsBackgroundVisible = YES;
        }
        authenticationRequestSource = BottomBar;
        [self authenticateWithAsha];
      }
    }
  }
}

- (void)authenticateWithAsha
{
  auth_ShareLoginVC *loginVC = [[auth_ShareLoginVC alloc] init];
  
  loginVC.messageText = enteredPostText;
  loginVC.messageKey = kFWMessagePostTextKey;
  
  loginVC.attach = messagePostImages;
  loginVC.attachKey = kFWMessagePostImagesKey;
  
  loginVC.notificationName = kFWMessagePostNotificationName;
  
  loginVC.appID = self.FWConnection.mFWAppID;
  loginVC.moduleID = self.FWConnection.mFWModuleID;
  
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginVC];
  navController.modalPresentationStyle = UIModalPresentationFormSheet;
  
  navController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
  navController.navigationBar.translucent = self.navigationController.navigationBar.translucent;
  navController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
  
  if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
    navController.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
  navController.navigationBar.titleTextAttributes = self.navigationController.navigationBar.titleTextAttributes;
  
  [self.navigationController presentViewController:navController animated:YES completion:nil];
  
}

#pragma mark - Keyboard notifications
- (void)keyboardWillShow:(NSNotification *)notification
{
  /* Move the toolbar to above the keyboard */
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
  [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  CGRect frame = self.inputToolbar.frame;
  
  CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  frame.origin.y = self.view.frame.size.height - self.inputToolbar.frame.size.height - keyboardFrame.size.height;
  
  self.inputToolbar.frame = frame;
  
  if(tabsBackgroundVisible){
    [self toggleTabsBackgroundVisibility];
    tabsBackgroundVisible = NO;
  }
  
  [UIView commitAnimations];
  keyboardIsVisible = YES;
  [self.inputToolbar.textView textViewDidChange:self.inputToolbar.textView.internalTextView];
  [self showKeyboard];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
  /* Move the toolbar back to bottom of the screen */
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
  [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
  [UIView setAnimationBeginsFromCurrentState:YES];
  
  CGRect frame = self.inputToolbar.frame;
  
  frame.origin.y = self.view.frame.size.height - self.inputToolbar.frame.size.height;
  self.inputToolbar.frame = frame;
  
  if(!tabsBackgroundVisible){
    [self toggleTabsBackgroundVisibility];
    tabsBackgroundVisible = YES;
  }
  
  [UIView commitAnimations];
  keyboardIsVisible = NO;
  
  if([self.view viewWithTag:kInputToolbarMaskViewTag]){
    [[self.view viewWithTag:kInputToolbarMaskViewTag] removeFromSuperview];
  }
}

- (void)showKeyboard
{
  if([self.view viewWithTag:kInputToolbarMaskViewTag]){
    [[self.view viewWithTag:kInputToolbarMaskViewTag] removeFromSuperview];
  }
  
  CGRect maskViewFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
  
  UIView *maskView = [[UIView alloc] initWithFrame:maskViewFrame];
  maskView.tag = kInputToolbarMaskViewTag;
  
  UITapGestureRecognizer *maskViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  maskViewTap.delegate = self;
  [maskView addGestureRecognizer:maskViewTap];
  
  [self.view insertSubview:maskView belowSubview:self.inputToolbar];
}

- (void)hideKeyboard
{
  enteredPostText = [self.inputToolbar.textView.text copy];
  
  [[self.view viewWithTag:kInputToolbarMaskViewTag] removeFromSuperview];
  
  [self.inputToolbar.textView resignFirstResponder];
}

#pragma mark -
- (void)postMessage
{
  typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
  TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
  {
    if ( [[response objectForKey:@"error"] length] )
    {
      [[[UIAlertView alloc] initWithTitle:@""
                                   message:NSBundleLocalizedString(@"mFW_postMessageFailedAlertMessage", @"Sending failed. Please try again")
                                  delegate:self
                         cancelButtonTitle:NSBundleLocalizedString(@"mFW_postMessageFailedAlertOkButtonTitle", @"OK")
                         otherButtonTitles:nil] show];
    } else {
      self.FWConnection.afterPost = YES;
      self.FWConnection.afterReply = YES;
      self.FWConnection.afterReply2 = YES;
      
      [self.inputToolbar clear];
      
      [self refreshWall];
      shouldScrollToTop = YES;
    }
  };
  
  [self.FWConnection postMessageWithParentID:@"0"
                                  andReplyID:@"0"
                                    withText:enteredPostText
                                   andImages:messagePostImages
                                     success:^(NSData *result, NSDictionary *response) {
                                       completionBlock(result, response, nil);
                                     }
                                     failure:^(NSError *error) {
                                       completionBlock(nil, nil, error);
                                     }];
}

-(void)handleSharingFromPhotoBrowser:(NSNotification *)notification
{
  NSString *postID = notification.userInfo[kAttachedPostIdKey];
  
  if(postID){
    [self requestSharingCountIncrementForPostID:postID];
    //do increment shares counter regardless of success of request to our  server
    //users should get feedback immidiately if sharing on fb/twtr succeeded
    //otherwise they might share once again and get a duplicate
    //[self updateSharesCountForPostId:postID];
  }
}

- (void)requestSharingCountIncrementForPostID:(NSString *)postID
{
  typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
  TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
  {
    if ( error || [[response objectForKey:@"error"] length] )
    {
      NSLog(@"mFanWall: increaseSharingCountForPostID error!");
      //inform user
    }
    else
    {
      NSLog(@"mFanWall: increaseSharingCountForPostID succeeded");
      [self refreshWall];
    }
  };
  
  
  [self.FWConnection increaseSharingCountForPost:postID
                                         success:^(NSData *result, NSDictionary *response) {
                                           completionBlock(result, response, nil);
                                         }
                                         failure:^(NSError *error) {
                                           completionBlock(nil, nil, error);
                                         }];
}

-(void)showNoMessagesLabel
{
  if(!self.noMessagesLabel){
    self.noMessagesLabel = [[UILabel alloc] initWithFrame:
                             CGRectZero];
    self.noMessagesLabel.backgroundColor = [UIColor clearColor];
    self.noMessagesLabel.textAlignment   = NSTextAlignmentCenter;
    self.noMessagesLabel.textColor       = self.FWConnection.mFWColorOfText;
    self.noMessagesLabel.text            = NSBundleLocalizedString(@"mFW_noMessagesYetString", @"No messages yet");
    [self.noMessagesLabel sizeToFit];
    self.noMessagesLabel.center = (CGPoint){self.view.center.x - kPostContentsPaddingLeft, self.wall.center.y};
    [self.refreshHeaderView addSubview:self.noMessagesLabel];
  } else {
    self.noMessagesLabel.hidden = NO;
  }
}

-(void)hideNoMessagesLabel
{
  if(self.noMessagesLabel && !self.noMessagesLabel.hidden){
    self.noMessagesLabel.hidden = YES;
  }
}

- (void)refreshWall
{
  if(!self.wall)
  {
    return;
  }
  
  self.view.userInteractionEnabled = NO;
  self.navigationController.navigationBar.userInteractionEnabled = NO;
  
  self.postID = self.lastPostID;
  
  self.hostReachable = [Reachability reachabilityWithHostName:[appIBuildAppHostName() stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  self.hostStatus = [self.hostReachable currentReachabilityStatus];
  
  if (self.hostStatus == NotReachable)
  {
    self.fwSettings.posts = [self.s_posts mutableCopy];
    [self didLoadPostsForRange:NSMakeRange(0, 0) strategy:ReloadExistingPosts];
  }
  else
  {
    NSUInteger countToLoad = [self.fwSettings.posts count];
    
    NSString *startPostId = [self.firstPostID copy];
    
    //REFRESH WALL
    if(![startPostId isEqualToString:@"0"])
    {
      startPostId = [NSString stringWithFormat:@"%ld", (long)[startPostId integerValue] - 1];
    }
    
    typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
    TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
    {
      NSMutableArray *mutablePosts = [self mutableSortedPosts:[response objectForKey:@"posts"]];
      
      NSRange range;
      
      //we can receive empty response, ie for wall with all messages deleted on server (by app owner/moderator)
      rowsToDelete = self.fwSettings.posts.count;
      
      NSUInteger postsCount = [mutablePosts count];
      
      if(postsCount < self.limit){
        mayLoadOlderPosts = NO;
      }
      
      if(postsCount > 0)
      {
        self.wallIsEmpty = NO;
        
        //This construct is needed to determine how many posts were ADDED on the server-side while our wall was empty
        //length of this range is used for insertion of this amount of rows in tableview
        if(!self.fwSettings.posts.count)
        { // wall was empty. let's insert added rows into tableview
          range = NSMakeRange(0, mutablePosts.count);
        } else { //wall was not empty. refresh of presented rows will do.
          range = NSMakeRange(0, 0);
        }
        
        if(countToLoad > 0){
          rowsToDelete = countToLoad - mutablePosts.count;
        }
        
        if(rowsToDelete > 0){
          [self.fwSettings.posts removeObjectsAtIndexes:[[NSIndexSet alloc]
                                                         initWithIndexesInRange:NSMakeRange(0, countToLoad)]];
          
          [self.fwSettings.posts insertObjects:mutablePosts
                                     atIndexes:[[NSIndexSet alloc]
                                                initWithIndexesInRange:NSMakeRange(0, mutablePosts.count)]];
        } else {
          //let's merge new posts into existent array
          if(self.fwSettings.posts.count)
          {
            [self.fwSettings.posts replaceObjectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, mutablePosts.count)]
                                               withObjects:mutablePosts];
          } else {
            //no previous posts? assign them posts from response
            self.fwSettings.posts = mutablePosts;
          }
        }
        
        self.firstPostID = [[self.fwSettings.posts objectAtIndex:self.fwSettings.posts.count - 1] objectForKey:@"post_id"];
        self.lastPostID = [[self.fwSettings.posts objectAtIndex:0] objectForKey:@"post_id"];
        
      } else {
        range = NSMakeRange(0, 0);

        self.wallIsEmpty = YES;
        self.fwSettings.posts = [NSMutableArray array];
        self.firstPostID = @"0";
        self.lastPostID  = @"0";
      }
      
      [self requestLikesAndShares];
      
      [UD setObject:[self.fwSettings.posts copy]
             forKey:@"s_posts_recent"];
      
      
      [self didLoadPostsForRange:range
                        strategy:ReloadExistingPosts]; /// ???
      
      [self loadNewerPosts];
    };
    
    //if there was always self.fwSettings.posts.count in case of 1 message we
    // did not receive more than 1 from server, ie we were stuck with single refreshing post
    
    [self.FWConnection getMessagesWithParentID:@"0"
                                    andReplyID:@"0"
                                     andPostID:startPostId // let's load latest self.fwsettings.posts.count messages
                                         limit:countToLoad
                                       success:^(NSData *result, NSDictionary *response)
                                       {
                                         completionBlock(result, response, nil);
                                       }
                                       failure:^(NSError *error)
                                       {
                                         completionBlock( nil, nil, error );
                                       }
     ];
  }
}

-(mFWSocialButton *)addSocialButtonWithFrame:(CGRect)frame andImageNamed:(NSString *)imageName toPostCell:(mFWPostCell *)cell
{
  mFWSocialButton *socialButton = [[mFWSocialButton alloc] initWithFrame:frame];
  socialButton.socialImage = [UIImage imageNamed:imageName];
  [cell.socialButtonsPane addSubview:socialButton];
  
  return socialButton;
}

-(mFWSocialButtonWithoutLikes *)addSocialButtonWithFrame1:(CGRect)frame andImageNamed:(NSString *)imageName toPostCell:(mFWPostCell *)cell
{
  mFWSocialButtonWithoutLikes *socialButton = [[mFWSocialButtonWithoutLikes alloc] initWithFrame:frame];
  socialButton.socialImage = [UIImage imageNamed:imageName];
  [cell.socialButtonsPane addSubview:socialButton];
  
  return socialButton;
}

- (void)commentsButtonTapped:(UIGestureRecognizer *)recognizer
{
  // To reload wall on return from map view
  // Why reload? Maybe we've got some new posts while browsing, so let's display them
  self.FWConnection.requiresRequest = YES;
  
  NSIndexPath *swipedIndexPath = [self.wall indexPathForRowAtPoint:[recognizer locationInView:self.wall]];
  self.FWConnection.activeCell = swipedIndexPath;
  mFWReplies *mFWRepliesVC = [[mFWReplies alloc] init];
  
  mFWRepliesVC.r1firstPost = [self.fwSettings.posts objectAtIndex:swipedIndexPath.row];
  mFWRepliesVC.r1replyID = @"0";
  mFWRepliesVC.r1parentID = [[self.fwSettings.posts objectAtIndex:swipedIndexPath.row] objectForKey:@"post_id"];
  mFWRepliesVC.firstTimeLoad = YES;
  
  aSha.delegate = self;
  
  [self.navigationController pushViewController:mFWRepliesVC animated:YES];
}

- (void)likesButtonTapped:(UIGestureRecognizer *)recognizer
{
  NSIndexPath *swipedIndexPath = [self.wall indexPathForRowAtPoint:[recognizer locationInView:self.wall]];
  NSDictionary *postToBeLiked = self.fwSettings.posts[swipedIndexPath.row];
  NSArray *images = [postToBeLiked objectForKey:@"images"];
  
  if(images){
    NSString *URL = images[0];
    aSha.delegate = self;
    
    [aSha postLikeForURL:URL
   withNotificationNamed:@"DoesNotReallyMatterBecauseFanwallUsesDelegate"
     shouldShowLoginRequiredPrompt:NO];
  }
}

- (void)sharesButtonTapped:(UIGestureRecognizer *)recognizer
{
  NSIndexPath *swipedIndexPath = [self.wall indexPathForRowAtPoint:[recognizer locationInView:self.wall]];
  self.FWConnection.activeCell = swipedIndexPath;
  
  [self showSharingActionSheet];
}

#pragma mark - Sharing flow

- (void)showSharingActionSheet
{
  [self getScreenshot];
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"general_sharingNoThanksButtonTitle", @"No Thanks")
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:NSLocalizedString(@"general_sharingTwitterButtonTitle", @"Twitter"),
                                 NSLocalizedString(@"general_sharingFacebookButtonTitle", @"Facebook"),NSLocalizedString(@"mFW_flagContent", @"Flag content"),
                                 nil];
  
  actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  [actionSheet showFromToolbar:self.navigationController.toolbar];
}


-(void)toggleTabsBackgroundVisibility
{
  CGFloat tabsBackgroundHeight = _tabsBackground.frame.size.height - tabsBackgroundSpacerHeight / 2;
  CGRect tabsBackgroundNewFrame = _tabsBackground.frame;
  CGRect newWallFrame = _wall.frame;
  
  if(tabsBackgroundVisible){
    tabsBackgroundNewFrame.origin.y -= tabsBackgroundHeight;
    newWallFrame.origin.y -= tabsBackgroundHeight;
  } else {
    tabsBackgroundNewFrame.origin.y += tabsBackgroundHeight;
    newWallFrame.origin.y += tabsBackgroundHeight;
  }
  
  _wall.frame = newWallFrame;
  _tabsBackground.frame = tabsBackgroundNewFrame;
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case 0:
    {
      if ([self checkReachabilityWithAlert:YES]){
        [self performSelector:@selector(shareTwitter) withObject:nil afterDelay:0.3f];
      }
      break;
    }
    case 1:
    {
      if ([self checkReachabilityWithAlert:YES]){
        [self performSelector:@selector(shareFacebook) withObject:nil afterDelay:0.3f];
      }
      break;
    }
    case 2:
    {
      if ([self checkReachabilityWithAlert:YES]){
        [self performSelector:@selector(reportClick) withObject:nil afterDelay:0.3f];
      }
      break;
    }
    default:
      NSLog(@"No Thanks");
      break;
  }
}

- (void) getScreenshot
{
  CALayer *layer = [[UIApplication sharedApplication] keyWindow].layer;
  CGFloat scale = [UIScreen mainScreen].scale;
  UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, scale);
  
  [layer renderInContext:UIGraphicsGetCurrentContext()];
  self.screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
}

- (void) reportClick
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NSMutableDictionary * formData = [NSMutableDictionary dictionary];
  [formData setObject:appProjectID() forKey:@"app_id"];
  [formData setObject:@"rep_forbidden_content" forKey:@"action"];
  
  [self postToUrl:[NSURL URLWithString:@"http://ibuildapp.com/endpoint/masterapp.php"]
             form:formData
         andImage:self.screenshotImage
         imageKey:@"screenshot"
            error:nil
returningResponse:nil];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  
  [UIView animateWithDuration:2.5f
                        delay:2.5f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
                   } completion:^(BOOL finished) {
                     NSString *msg = NSLocalizedString(@"masterApp_ComolainSended", @"Your complain has been sent and will be consider in short");
                     
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                     message:msg
                                                                    delegate:nil
                                                           cancelButtonTitle:nil
                                                           otherButtonTitles:@"OK", nil];
                     [alert show];
                   }];
}

- (NSData *)postToUrl:(NSURL*)url form:(NSDictionary*)form andImage:(UIImage*)img imageKey:(NSString*)imageKey error:(NSError**)error returningResponse:(NSURLResponse**)response
{
  NSLog(@"postToUrl:%@ Form:%@ andImage:%@ imageKey:%@",url,form,img,imageKey);
  NSString *boundary = @"------WebKitFormBoundaryO74I2GrJDX6YLZB8";
  NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"POST"];
  [request setTimeoutInterval:15.0];
  [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
  
  NSMutableData *body = [NSMutableData data];
  
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"screenshot.jpg\"\r\n", imageKey] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[NSData dataWithData:UIImageJPEGRepresentation(img, 1)]];
  
  for (NSString *key in [form allKeys])
  {
    NSString *value = [form objectForKey:key];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@",key, value] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  
  [request setHTTPBody:body];
  return [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
}

- (void)shareTwitter
{
  NSString *template = [NSString stringWithFormat:NSBundleLocalizedString(@"mFW_shareMessageTemplate", nil), self.FWConnection.appName];
  
  NSString *link    = nil;
  NSIndexPath *indexPath = self.FWConnection.activeCell;
  
  if (!(indexPath && self.fwSettings.posts && indexPath.row < self.fwSettings.posts.count))
  {
    NSLog(@"mFanWall: shareTwitter can not determine active post!");
    return;
  }
  
  NSDictionary *currentDict = self.fwSettings.posts[indexPath.row];

  NSMutableString *message;
  
  message = [NSMutableString stringWithString:template];
  
  // find image link
  NSArray *images = currentDict[@"images"];
  
  if (images && images.count){
    link = images[0];
    
    NSArray *visibleCells = [self.wall visibleCells];
    
    NSIndexPath *startingIndexPath = [self.wall indexPathForCell:visibleCells[0]];
    NSUInteger cellOfInterestRow = self.FWConnection.activeCell.row - startingIndexPath.row;

    mFWPostCell *cell = (mFWPostCell *) visibleCells[cellOfInterestRow];
    
    UIImageView *imageView = cell.attachedThumbnailImageView;
    
    aSha.viewController = self;
    aSha.delegate = self;
    
    [self showActivityIndicator];
    
    NSURL *URL = [NSURL URLWithString:[link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [[SDWebImageManager sharedManager] downloadWithURL:URL delegate:self options:SDWebImageProgressiveDownload success:^(UIImage *image, BOOL cached) {
      
      NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                            image, @"image", nil];
      
      
      [aSha shareContentUsingService:auth_ShareServiceTypeTwitter fromUser:aSha.user withData:data];
      
      [self hideIndicator];
      
    } failure:^(NSError *error) {
      NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                            imageView.image ? imageView.image : self.placeholderImage,
                            @"image", nil];
      
      [self hideIndicator];
      
      [aSha shareContentUsingService:auth_ShareServiceTypeTwitter fromUser:aSha.user withData:data];
    }];
  }
}


- (void)shareFacebook
{
  NSString *template = [NSString stringWithFormat:NSBundleLocalizedString(@"mFW_shareMessageTemplate", nil), self.FWConnection.appName];
  
  NSString *link    = nil;
  NSIndexPath *indexPath = self.FWConnection.activeCell;
  
  if (!(indexPath && self.fwSettings.posts && indexPath.row < self.fwSettings.posts.count))
  {
    NSLog(@"mFanWall: shareFacebook can not determine active post!");
    return;
  }
  
  NSDictionary *currentDict = self.fwSettings.posts[indexPath.row];
  
  NSMutableString *message;
  
  message = [NSMutableString stringWithString:template];

  NSArray *images = currentDict[@"images"];
  if (images && images.count){
    link = images[0];
    [message appendFormat:@"%@ ", link];
  }
  
  NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                        message, @"message",
                        [link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"link", nil];
  
  
  aSha.viewController = self;
  aSha.delegate = self;
  [aSha shareContentUsingService:auth_ShareServiceTypeFacebook
                        fromUser:aSha.user
                        withData:data
         showLoginRequiredPrompt:NO];
}

-(void)fillLikesAndSharesForPosts:(NSArray *)posts
{
  NSMutableSet *urlsToLoadLikes = [NSMutableSet set];
  
  for (NSDictionary *post in posts)
  {
    NSArray *images = [post objectForKey:@"images"];
    
    if ( [images count] )
    {
      NSString *URL = images[0];
      [urlsToLoadLikes addObject:URL];
      
      NSNumber *currentSharingQty = [self.sharesCountForPosts objectForKey:URL];
      NSNumber *newSharesQty = [post objectForKey:@"sharing_count"];
      
      if(!currentSharingQty || ([newSharesQty integerValue] > [currentSharingQty integerValue])){
        [self.sharesCountForPosts setObject:(newSharesQty ? newSharesQty : @0) forKey:URL];
      }
    }
  }
  
  if([urlsToLoadLikes count]){
    [aSha loadFacebookLikesCountForURLs:urlsToLoadLikes];
  }
}

#pragma mark - auth_ShareDelegate

- (void)didShareDataForService:(auth_ShareServiceType)serviceType error:(NSError *)error
{
  if (error)
  {
    NSLog(@"mFanWall: doneSharingDataForService:withError: %@", [error localizedDescription]);
    return;
  }
  else
  {
    NSLog(@"mFanWall: doneSharingDataForService:withError: success!");
    
    NSIndexPath *indexPath = self.FWConnection.activeCell;
    
    if (!(indexPath && self.fwSettings.posts && indexPath.row < self.fwSettings.posts.count))
    {
      NSLog(@"mFanWall: done sharing can not determine active post!");
      return;
    }
    
    NSDictionary *currentPost = [self.fwSettings.posts objectAtIndex:indexPath.row];
    
    NSString *postID = [currentPost objectForKey:@"post_id"];
    
    if (postID) {
      [self requestSharingCountIncrementForPostID:postID];
      //do increment shares counter regardless of success of request to our  server
      //users should get feedback immidiately if sharing on fb/twtr succeeded
      //otherwise they might share once again and get a duplicate
      //[self updateSharesCountForPostId:postID];
    }
  }
}

- (void)didLoadFacebookLikesCount:(NSDictionary *)likes error:(NSError *)error
{
  if(!error){
    for(NSString *URL in likes.keyEnumerator){
      
      long likesCount = [[likes objectForKey:URL] longValue];
      
      [self.facebookLikesForPosts setObject:[NSNumber numberWithLong:likesCount] forKey:URL];
      
      if(self.wall){
        NSInteger postIndex = [self postIndexForFieldNamed:@"images" withValue:URL];
        if(postIndex != -1){
          [self updateCellAtRow:postIndex];
        }
      }
    }
  }
}

- (void)didLoadFacebookLikedURLs:(NSMutableSet *)likedItems error:(NSError *)error
{
  if(!error){
    self.facebookLikedItems = [likedItems mutableCopy];
    
    [UD setObject:self.facebookLikedItems.allObjects forKey:self.facebookLikedItemsUDKey];
    
    dispatch_async(GCDBackgroundThread, ^{
      [UD synchronize];
    });
    
    if(self.wall){
      [self updateVisibleCells];
    }
  }
}

- (void)didFacebookLikeForURL:(NSString*)URL error:(NSError *)error
{
  if(!error){
    if(![self.facebookLikedItems containsObject:URL]){
      NSLog(@"mFanWall: URL %@ liked successfully", URL);
      [self.facebookLikedItems addObject:URL];
      
      NSNumber *currentLikesCount = [self.facebookLikesForPosts objectForKey:URL];
      NSInteger incrementedLikesCount = [currentLikesCount integerValue] + 1;
      
      [self.facebookLikesForPosts setObject:[NSNumber numberWithInteger:incrementedLikesCount] forKey:URL];
      
      NSInteger postIndex = [self postIndexForFieldNamed:@"images" withValue:URL];
      if(postIndex != -1){
        [self updateCellAtRow:postIndex];
      }
    }
  }
}

- (void)didAuthorizeOnService:(auth_ShareServiceType)serviceType error:(NSError *)error
{
  if(serviceType == auth_ShareServiceTypeFacebook){
    if(!error){
      aSha.delegate = self;
      [aSha loadFacebookLikedURLs];
    }
  }
}

#pragma mark mFWInputToolbarDelegate
-(void)mFWInputToolbarDidToggleGeolocation:(mFWInputToolbar *)toolbar
{
  BOOL oldLocationTrackingState = [self.FWConnection isLocationTrackingEnabled];
  BOOL newLocationTrackingState = [self.FWConnection toggleGeolocationForToolbar:toolbar];
  
  if(newLocationTrackingState != oldLocationTrackingState){
    [self.FWConnection saveLocationTrackingEnabledToUserDefaults:newLocationTrackingState];
    self.FWConnection.isLocationTrackingEnabled = newLocationTrackingState;
  }
}

#pragma mark -

-(void)requestLikesAndShares
{
  aSha.delegate = self;
  [self fillLikesAndSharesForPosts:self.fwSettings.posts];
  
  if(aSha.user.authentificatedWith == auth_ShareServiceTypeFacebook){
    [aSha loadFacebookLikedURLs];
  }
}

- (void)adjustWallToAuxiliaryToolbar:(NSNotification *)notification
{
  CGFloat insetBottom = [[notification.userInfo objectForKey:kAuxiliaryToolbarToggledHeightDiffNotificationKey] floatValue];
  
  UIEdgeInsets newWallInset = self.wall.contentInset;
  newWallInset.bottom += insetBottom;
  
  [UIView animateWithDuration:kAuxiliaryToolbarTogglingAnimationDuration animations:^{
    self.wall.contentInset = newWallInset;
  }];
}

-(void)refreshInputToolbarGeolocationIndicator
{
  [self.FWConnection refreshInputToolbarGeolocationIndicator:self.inputToolbar];
}

-(NSInteger)postIndexForFieldNamed:(NSString *)fieldName withValue:(NSString *)value
{
  NSInteger count = self.fwSettings.posts.count;
  
  for(NSInteger index = 0; index < count; index++){
    NSDictionary *post = self.fwSettings.posts[index];
    
    id field = post[fieldName];
    
    if(field){
      
      if([field isKindOfClass:[NSArray class]] && [field count]){
        field = field[0];
      } else if ([field isKindOfClass:[NSDictionary class]]){
        return -1;
      }
      
      if([field isKindOfClass:[NSString class]]){
        if([field isEqualToString:value]){
          return index;
        }
      }
    }
  }
  
  return -1;
}

-(void)updateVisibleCells
{
  NSArray *visibleRows = [self.wall indexPathsForVisibleRows];
  NSArray *visibleCells = [self.wall visibleCells];
  
  if(visibleRows.count && visibleCells.count){
    NSInteger startingRow = ((NSIndexPath *)visibleRows[0]).row;
    
    for(NSIndexPath *path in visibleRows){
      NSUInteger row = path.row;
      mFWPostCell *cell = (mFWPostCell *)visibleCells[row - startingRow];
      
      [self updateCell:cell withPostAtRow:row];
    }
  }
}

-(void)updateCellAtRow:(NSUInteger)row
{
  NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
  NSArray *visibleRows = [self.wall indexPathsForVisibleRows];
  
  if([visibleRows containsObject:path]){
    NSUInteger visibleCellIndex = [visibleRows indexOfObject:path];
    
    NSArray *visibleCells = [self.wall visibleCells];
    if(visibleCells.count){
      [self updateCell:visibleCells[visibleCellIndex] withPostAtRow:row];
    }
  }
}

-(void)updateCell:(mFWPostCell *)cell withPostAtRow:(NSUInteger)row;
{
    NSDictionary *post = self.fwSettings.posts[row];//*

    //if we have image in cell, but not in updated post dictionary
    //or we do not have an image in cell but updated post has an image
    //each case we reload cell from scratch
    if(cell.attachedThumbnailImageViewContainer.hidden == ([post[@"thumbs"] count] > 0)){
        [self.wall reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        return;
    } else if([post[@"thumbs"] count] && ![cell.attachedImageThumbnailURL isEqualToString:post[@"thumbs"][0]]){
        [cell setAttachedImageThumbnailForURL:post[@"thumbs"][0] withPlaceholderImage:self.placeholderImage];
        return;
    }
    
    //if updated post's message has different size we reload cell to accomodate to new size
    if(![self doesSizeOfUpdatedPostMessageText:post[@"text"] matchSizeOfProvidedLabel:cell.postMessageLabel]){
        [self.wall reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    
    cell.userNameLabel.text = [post objectForKey:@"user_name"];
    
    double dateDouble = [[post objectForKey:@"create"] doubleValue] / 1000;
    NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:dateDouble];
    NSString *dateDiff = [mFWSettings dateDiffForDate:postDate];
    cell.postDateLabel.text = [dateDiff isEqualToString:@"(null)"] ? NSBundleLocalizedString(@"mFW_dateDiffJustNow", @"Just now") : dateDiff;
    
    cell.postMessageLabel.text = post[@"text"];
    
    cell.commentsButton.socialActionsCount = [post[@"total_comments"] integerValue];
    
    if(post[@"images"] && [post[@"images"] count]){
        
        if(cell.likesButton && !cell.likesButton.hidden){
            NSString *imageURL = [[post objectForKey:@"images"] objectAtIndex:0];
            NSNumber *likesCount = [self.facebookLikesForPosts objectForKey:imageURL];
            
            cell.likesButton.socialActionsCount = [likesCount integerValue];
            
            if(!cell.likesButton.socialImageView.highlighted){
                if([self.facebookLikedItems containsObject:imageURL]){
                    cell.likesButton.socialImageView.highlighted = YES;
                    cell.likesButton.userInteractionEnabled = NO;
                }
            }
        }
        
        if(cell.sharesButton && !cell.sharesButton.hidden){
            NSString *imageURL = [[post objectForKey:@"images"] objectAtIndex:0];
            NSNumber *sharesQty = [self.sharesCountForPosts objectForKey:imageURL];
            
            cell.sharesButton.socialActionsCount = [sharesQty integerValue];
        }
        
    }
}

-(BOOL)doesSizeOfUpdatedPostMessageText:(NSString *)text
               matchSizeOfProvidedLabel:(UILabel *)label
{
    //workaround for text sizeForFont... method returning non-zero value for empty string
    //meanwhile cell has CGSizeZero for label for empty string
    if(!text.length && !label.text.length){
        return YES;
    }

    CGSize newSize = [text sizeForFont:label.font
                             //280 == CGFloat maxPostContentWidth = cell.frame.size.width - 2 * kPostContentOffsetX;
                             limitSize:(CGSize){280.0f, INT32_MAX} 
                         lineBreakMode:label.lineBreakMode];
    
    CGSize oldSize = label.bounds.size;
    
    return newSize.height == oldSize.height;
}

-(void)increaseSharesCountForPostId:(NSString *)postID
{
  NSUInteger postIndex = [self postIndexForFieldNamed:@"post_id" withValue:postID];
  if(postIndex != -1){
    
    NSMutableDictionary *post = self.fwSettings.posts[postIndex];
    
    if([post[@"images"] count]){
      NSString *URL = self.fwSettings.posts[postIndex][@"images"][0];
      NSNumber *sharesQty = [self.sharesCountForPosts objectForKey:URL];
      
      if(!sharesQty){
        sharesQty = @0;
      }
      
      NSInteger incrementedSharesCount = [sharesQty integerValue] + 1;
      sharesQty = [NSNumber numberWithInteger:incrementedSharesCount];
      [self.sharesCountForPosts setObject:sharesQty forKey:URL];
      
      [post setObject:sharesQty forKey:@"sharing_count"];
      
      [self updateCellAtRow:postIndex];
    }
  }
}

-(void)showActivityIndicator
{
  self.view.userInteractionEnabled = NO;
  self.navigationController.navigationBar.userInteractionEnabled = NO;
  
  if(![self.view viewWithTag:kSpinnerViewTag]){
    UIView *spinner = [self.FWConnection showIndicatorWithCenter:downloadIndicatorCenter inView:self.view];
    spinner.tag = kSpinnerViewTag;
  }
}

- (void)hideIndicator
{
  self.view.userInteractionEnabled = YES;
  self.navigationController.navigationBar.userInteractionEnabled = YES;
  [self.FWConnection hideIndicator];
}

-(NSMutableArray *)mutableSortedPosts:(NSArray *)posts
{
  NSArray *sortedPosts;
  
  sortedPosts = [posts sortedArrayUsingComparator:^NSComparisonResult(id one, id another) {
    
    NSDictionary *post = (NSDictionary *)one;
    NSDictionary *anotherPost = (NSDictionary *)another;
    
    NSInteger postId = [post[@"post_id"] integerValue];
    NSInteger anotherPostId = [anotherPost[@"post_id"] integerValue];
    
    NSComparisonResult result = NSOrderedSame;
    
    if(postId > anotherPostId)
    {
      result = NSOrderedAscending;
    } else if(postId < anotherPostId){
      result = NSOrderedDescending;
    }
    
    return result;
  }];
  
  return [sortedPosts mutableCopy];
}

@end
