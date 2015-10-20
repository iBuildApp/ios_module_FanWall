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


#import "mFWReplies.h"
#import "mFWPostCell.h"
#import "mFWRepliesCell.h"
#import "mFWProfile.h"
#import "mFWSettings.h"

#import "Reachability.h"
#import <Smartling.i18n/SLLocalization.h>

#import <auth_Share/auth_Share.h>
#import <auth_Share/auth_ShareLoginVC.h>

#import "mFWPhotoBrowser.h"
#import "UIColor+HSL.h"
#import "UIImage+SolidColorPlaceholder.h"
#import "appconfig.h"
#import <objc/runtime.h>

#define kLeftMargin 10.f
#define kTopMargin  10.f
#define kLogoWidth  36.f
#define kLogoHeight 36.f
#define kTopCommentsBarHeight 29.f
#define kSpaceBetweenLogoAndPostText 5.5f

#define kBaseBackgroundObfuscation 0.2f
#define kHeaderBackgroundObfuscation 0.2f
#define kHeaderCommentsBackgroundObfuscation 0.1f
#define kImageViewBorder 0.0f

#define kDefaultCommentsCount   20

#define kSpaceBetweenSeparatorAndNextCell 10.0f

#define kAshaFWNewReply @"mFWNewReply"
#define kSeparatorColor [UIColor colorWithWhite:1.0 alpha:0.2]
#define kSeparatorColorForWhiteBackground [UIColor colorWithWhite:0.0 alpha:0.2]

#define kSpaceBetweenMessageAndImage 11.0f

typedef enum {
  LoadRepliesAtStart,
  LoadNewerReplies,
  LoadOlderReplies
} RepliesLoadingStrategy;

typedef enum {
  BottomBar,
  PostScreen,
  None
} AuthenticationRequestSource;

@interface mFWReplies (){
  int postNumToGo;
  
  NSString *enteredText;
  NSArray *replyImages;
  
  BOOL keyboardIsVisible;
  
  //If not authenticated, we go to authentication by clicking send button on bottom bar
  //after authentication we get back to comments list and replies start refreshing (loadNewerReplies method)
  //at this time the postReply method executes and starts refreshing replies too.
  //BUT it starts refreshing at the same index, that first call did.
  //after they get completed both, we have two identical first comments in list (not on the server).
  //This flag prevents the second call to loadNewerReplies
  BOOL mayLoadNewerReplies;
  
  auth_Share *aSha;
  AuthenticationRequestSource authenticationRequestSource;
  
  BOOL canEdit;
  UIBarButtonItem *backBarButton;
  
  /**
   * Indicates that we did not loaded the oldest reply and therefore may
   * proceed sending requests and show loading indicator
   */
  BOOL mayLoadOlderPosts;
}
  @property(nonatomic, strong) UITableView    *replies;
  @property (nonatomic, strong) UIView *headerView;

  @property(nonatomic, strong) mFWConnection  *FWConnection;
  @property(nonatomic, strong) NSMutableArray *rep1Posts;
  @property(nonatomic, strong) NSMutableArray *s_rep1Posts;

  @property(nonatomic, strong) NSString       *firstPostID;
  @property(nonatomic, strong) NSString       *lastPostID;
  @property(nonatomic, strong) Reachability   *hostReachable;
  @property(nonatomic, assign) NetworkStatus  hostStatus;
  @property(nonatomic, assign) BOOL           reachable;
//  @property(nonatomic, strong) NSUserDefaults *UD;

  @property(nonatomic, assign) BOOL          onePost;
  @property(nonatomic, assign) CGFloat       secondCellHeight;


  @property(nonatomic, assign) BOOL tabBarIsHidden;

  @property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
  /**
   Indicates that we do pull-to-refresh (and do not need to show spinner, for example)
   */
  @property BOOL reloading;
  @property (nonatomic, strong) UILabel *commentsLabel;
  @property (nonatomic, strong) UILabel *noCommentsYetLabel;

  //i.e. not comment to comment
  @property BOOL isFirstLevelComment;

  @property (nonatomic, retain) mFWInputToolbar *inputToolbar;

  @property (nonatomic, strong) UIImage *placeholderImage;

@end

@implementation mFWReplies

@synthesize r1parentID = _r1parentID,
             r1replyID = _r1replyID,
           r1firstPost = _r1firstPost,
                photos = _photos;

@synthesize replies = _replies,
         headerView = _headerView,
       FWConnection = _FWConnection,
          rep1Posts = _rep1Posts,
        s_rep1Posts = _s_rep1Posts,
        firstPostID = _firstPostID,
         lastPostID = _lastPostID,
      hostReachable = _hostReachable;

@synthesize tabBarIsHidden,
            reachable,
            hostStatus;

#pragma mark -
- (id)init
{
    self = [super init];
    if (self)
    {
      self.onePost          = NO;
      self.secondCellHeight = 0.f;
      self.hostStatus       = ReachableViaWiFi;
      self.tabBarIsHidden   = YES;
      self.reachable        = YES;
      _r1parentID  = nil;
      _r1replyID   = nil;
      _r1firstPost = nil;
      
      _headerView    = nil;
      _replies       = nil;
      _FWConnection  = nil;
      _rep1Posts     = nil;
      _s_rep1Posts   = nil;
      _firstPostID   = nil;
      _lastPostID    = nil;
      _hostReachable = nil;
      _firstTimeLoad = YES;
      _isFirstLevelComment = YES;
      postNumToGo = 0;
      _noCommentsYetLabel = nil;
      _inputToolbar = nil;
      enteredText = nil;
      replyImages = nil;
      
      keyboardIsVisible = NO;
      
      authenticationRequestSource = None;
      
      mayLoadNewerReplies = YES;
      canEdit = NO;
      backBarButton = nil;
      self.placeholderImage = [UIImage placeholderWithSize:(CGSize){300.0f, 300.0f} andColor:[[UIColor blackColor] colorWithAlphaComponent:0.2f]];
      
      mayLoadOlderPosts = YES;
    }
    return self;
}

- (void)dealloc
{
  self.r1parentID  = nil;
  self.r1replyID   = nil;
  self.r1firstPost = nil;
  
  if (self.photos){
    [self.photos release];
  }
  self.photos      = nil;
  
  self.replies       = nil;
  self.FWConnection  = nil;
  self.rep1Posts     = nil;
  self.s_rep1Posts   = nil;
  self.firstPostID   = nil;
  self.lastPostID    = nil;
  self.hostReachable = nil;

  self.commentsLabel = nil;
  self.noCommentsYetLabel = nil;
  self.inputToolbar = nil;
  
  if(enteredText != nil)
  {
    [enteredText release];
    enteredText = nil;
  }
  if(replyImages != nil)
  {
    replyImages = nil;
  }
  
  if(backBarButton != nil){
    [backBarButton release];
    backBarButton = nil;
  }
  
  self.placeholderImage = nil;
  
  [super dealloc];
}

#pragma mark -
#pragma mark view life cycle
- (void)viewWillAppear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reachabilityChanged:)
                                               name:kReachabilityChangedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:self.hostReachable];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustWallToAuxiliaryToolbar:) name:kAuxiliaryToolbarToggledNotificationName object:nil];
  
  //for checking changes in notification state when returned from settings app
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refreshInputToolbarGeolocationIndicator)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];

  [self.navigationController setNavigationBarHidden:NO animated:NO];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

  // hide tab bar
  self.tabBarIsHidden = [[self.tabBarController tabBar] isHidden];
  if ( !self.tabBarIsHidden )
    [[self.tabBarController tabBar] setHidden:YES];
  
  self.navigationController.navigationBar.topItem.backBarButtonItem = backBarButton;
  
  if(self.inputToolbar != nil){
    [self.FWConnection refreshInputToolbarGeolocationIndicator:self.inputToolbar];
  }
  
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  self.isFirstLevelComment = self.r1replyID != nil && [self.r1replyID isEqualToString:@"0"];
  
  if(self.firstTimeLoad){
    [self loadRepliesAtStart];
    self.firstTimeLoad = NO;
  } else {
    [self loadNewerReplies];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuxiliaryToolbarToggledNotificationName object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
  
  [[self.tabBarController tabBar] setHidden:self.tabBarIsHidden];
  [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
  self.FWConnection = [mFWConnection sharedInstance];
  
  canEdit = ( [self.FWConnection.mFWCanEdit isEqualToString:@"comment"] ) ||
  ( [self.FWConnection.mFWCanEdit isEqualToString:@"all"] );
  
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  
  self.navigationItem.title = NSBundleLocalizedString(@"mFW_commentsPageTitle", @"Comments");
  
  
  self.FWConnection.requiresRequest = YES;
  
  self.firstPostID = [[NSString new] autorelease];
  
  self.rep1Posts = [NSMutableArray array];
  
  self.view.backgroundColor = self.FWConnection.mFWColorOfBackground;
  
  self.hostReachable = [Reachability reachabilityWithHostName:[functionLibrary hostNameFromString:[[NSString stringWithFormat:@"http://%@", appIBuildAppHostName()] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
  self.hostStatus = [self.hostReachable currentReachabilityStatus];
  
  self.reachable = self.hostStatus;

  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.view.autoresizesSubviews = YES;
  
  [self createHeaderView];

  [self setupReplies];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleMessagePosting:)
                                               name:kAshaFWNewReply
                                             object:nil];
  aSha = [auth_Share sharedInstance];
  aSha.viewController = self;
  aSha.messageProcessingBlock = nil;
  
  backBarButton = [[UIBarButtonItem alloc] init];
  backBarButton.title = self.navigationController.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"mFW_backToWallButtonTitle", @"Wall");
  
  [super viewDidLoad];
}

- (void) viewDidUnload
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kAshaFWNewReply object:nil];
  [super viewDidUnload];
}

#pragma mark - 

- (void)createHeaderView
{
  self.headerView = [[[UIView alloc] init] autorelease];
  self.headerView.frame = (CGRect){0, 0, self.view.bounds.size.width, 100};
  self.headerView.backgroundColor = [UIColor colorWithWhite:0 alpha:kHeaderBackgroundObfuscation];
  
  UILabel   *nameLabel;
  UILabel   *dateLabel;
  UILabel   *textLabel;
  UIImageView *logoImageView;
  UIView      *attachedImageView = nil;
  UIImageView *phImageView = nil;
  
  nameLabel = [[UILabel alloc] init];
  nameLabel.frame = CGRectMake(kLeftMargin*2 + kLogoWidth, kTopMargin, self.headerView.bounds.size.width - (kLeftMargin*3 + kLogoWidth), 22);
  nameLabel.tag = 1;
  nameLabel.font = [UIFont boldSystemFontOfSize:14.0f];
  nameLabel.textColor = self.FWConnection.mFWColorOfTextHeader;
  nameLabel.text = [self.r1firstPost objectForKey:@"user_name"];
  nameLabel.backgroundColor = [UIColor clearColor];
  
  [self.headerView addSubview:nameLabel];
  [nameLabel release];
  
  dateLabel = [[UILabel alloc] init];
  dateLabel.frame = CGRectMake(kLeftMargin*2 + kLogoWidth, kTopMargin + 20, self.headerView.bounds.size.width - (kLeftMargin*3 + kLogoWidth), 15);
  dateLabel.tag = 2;
  dateLabel.font = [UIFont systemFontOfSize:13.0f];
  dateLabel.textColor = self.FWConnection.mFWColorOfTextHeader;
  dateLabel.alpha = 0.8f;
  dateLabel.backgroundColor = [UIColor clearColor];
  dateLabel.textAlignment = NSTextAlignmentLeft;
  
  [self.headerView addSubview:dateLabel];
  [dateLabel release];
  
  logoImageView = [[UIImageView alloc] initWithFrame:(CGRect){kLeftMargin, kTopMargin, kLogoWidth, kLogoHeight}];
  logoImageView.tag = 3;
  logoImageView.contentMode = UIViewContentModeScaleAspectFill;
  logoImageView.userInteractionEnabled = YES;
  logoImageView.layer.cornerRadius = 4.0f;
  logoImageView.layer.masksToBounds = YES;
 // logoImageView.contentMode = UIViewContentModeScaleToFill;
  
  UITapGestureRecognizer *avatarImageTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(showUserProfile:)];
  avatarImageTap.delegate = self;
  [logoImageView addGestureRecognizer:avatarImageTap];
  
  [avatarImageTap release];

  [self.headerView addSubview:logoImageView];
  [logoImageView release];
  
  
  textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  textLabel.tag = 4;
  textLabel.font = [UIFont systemFontOfSize:15.0f];
  textLabel.textColor = self.FWConnection.mFWColorOfText;
  textLabel.textAlignment = NSTextAlignmentLeft;
  textLabel.numberOfLines = 0;
  textLabel.backgroundColor = [UIColor clearColor];
  
  [self.headerView addSubview:textLabel];
  [textLabel release];
  
  
  if ( [[self.r1firstPost objectForKey:@"user_avatar"] length] )
  {
    
    SDWebImageSuccessBlock fadeInBlock = ^(UIImage *image, BOOL cached)
    {
      if(!cached){
        logoImageView.alpha = 0.0f;
        [UIView animateWithDuration:kFadeInDuration animations:^{
          logoImageView.alpha = 1.0f;
        }];
      }
    };
    
    [logoImageView setImageWithURL:[NSURL URLWithString:[[self.r1firstPost objectForKey:@"user_avatar"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                   placeholderImage:[UIImage imageNamed:resourceFromBundle(@"_mFW_big_ava")]
                            success:fadeInBlock
                            failure:nil];
    
    [fadeInBlock release];
  }
  else
  {
    logoImageView.image = [UIImage imageNamed:resourceFromBundle(@"_mFW_big_ava")];
  }
  
  double dateDouble = 0.f;
  NSString *dateString = [self.r1firstPost objectForKey:@"create"];
  if (dateString)
    dateDouble = dateString.doubleValue / 1000;
  
  if (dateDouble)
  {
    NSDate *dateDate = [NSDate dateWithTimeIntervalSince1970:dateDouble];
    dateLabel.text = [mFWSettings dateDiffForDate:dateDate];
  }
  
  NSString *messageText = [self.r1firstPost objectForKey:@"text"];
  if (messageText.length)
  {
    CGSize labelSize = [messageText sizeForFont:textLabel.font
                                      limitSize:CGSizeMake(self.headerView.bounds.size.width - 2*kLeftMargin, 300)
                                nslineBreakMode:NSLineBreakByTruncatingTail];
    
    textLabel.frame = (CGRect){kLeftMargin, kTopMargin + kLogoHeight + kSpaceBetweenLogoAndPostText, labelSize.width, labelSize.height};
    textLabel.text = messageText;
    
    NSLog(@"Text label: %@", textLabel);
  }
  
  if ( [[self.r1firstPost objectForKey:@"images"] count] )
  {
    CGFloat imageWidth = self.headerView.frame.size.width - 2*kLeftMargin;
    
    CGFloat effectiveTextLabelHeight = textLabel.frame.size.height ? textLabel.frame.size.height + 3 : 0;
    
    attachedImageView = [[UIView alloc] initWithFrame:CGRectMake(kLeftMargin,
                                                                 kTopMargin + kLogoHeight + effectiveTextLabelHeight + kSpaceBetweenLogoAndPostText + kSpaceBetweenMessageAndImage, //+ 3,
                                                                 imageWidth,
                                                                 imageWidth)];
    attachedImageView.backgroundColor = [UIColor whiteColor];

    phImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kImageViewBorder,
                                                                kImageViewBorder, attachedImageView.frame.size.width - 2*kImageViewBorder,
                                                                attachedImageView.frame.size.height - 2*kImageViewBorder)];
    [attachedImageView addSubview:phImageView];

    SDWebImageSuccessBlock fadeInBlock = ^(UIImage *image, BOOL cached)
    {
      if(!cached){
        phImageView.alpha = 0.0f;
        [UIView animateWithDuration:kFadeInDuration animations:^{
          phImageView.alpha = 1.0f;
        }];
      }
    };

      NSString *imageURL = self.r1firstPost[@"images"][0];
      const char *key = [kAttachedPostIdKey UTF8String];
      objc_setAssociatedObject(imageURL, key, self.r1firstPost[@"post_id"], OBJC_ASSOCIATION_RETAIN);
      
    [phImageView setImageWithURL:[NSURL URLWithString:[imageURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                placeholderImage:self.placeholderImage
                         success:fadeInBlock
                         failure:nil];
    
    [fadeInBlock release];
    
    
    phImageView.contentMode = UIViewContentModeScaleAspectFill;
    phImageView.clipsToBounds = YES;

    [phImageView release];

    [self.headerView addSubview:attachedImageView];
    attachedImageView.userInteractionEnabled = YES;

    UITapGestureRecognizer *attachedImageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHeaderViewAttachedImage)];

    attachedImageTap.delegate = self;
    [attachedImageView addGestureRecognizer:attachedImageTap];
    [attachedImageView release];
  }
  
  CGFloat attachedImageViewHeight = 0;
  if (attachedImageView)
    attachedImageViewHeight = attachedImageView.frame.size.height + kSpaceBetweenMessageAndImage;
    
  
  CGRect headerNewFrame = self.headerView.frame;
  headerNewFrame.size.height = 2*kTopMargin + kLogoHeight + textLabel.frame.size.height +
                               kSpaceBetweenLogoAndPostText + attachedImageViewHeight + kTopCommentsBarHeight + 3.0f; // 3.0 for bigger space between image and comments count
  self.headerView.frame = headerNewFrame;


  self.commentsLabel = [[UILabel alloc] init];
  self.commentsLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:kHeaderCommentsBackgroundObfuscation];
  self.commentsLabel.frame = CGRectMake(0, headerNewFrame.size.height - kTopCommentsBarHeight, headerNewFrame.size.width, kTopCommentsBarHeight);
  self.commentsLabel.textColor = self.FWConnection.mFWColorOfTextHeader;
  self.commentsLabel.textAlignment = NSTextAlignmentCenter;
  self.commentsLabel.font = [UIFont systemFontOfSize:14];

  NSNumber *number = [self.r1firstPost objectForKey:@"total_comments"];
  self.commentsLabel.text = [NSString stringWithFormat:SLBundlePluralizedString(@"mFW_proflie_%@ comments", number, nil), number];
  
  [self.headerView addSubview:self.commentsLabel];
  
  UIView *topBorder = [[[UIView alloc] initWithFrame:CGRectMake(0, headerNewFrame.size.height - kTopCommentsBarHeight - 1, headerNewFrame.size.width, 1)] autorelease];
  topBorder.backgroundColor = kSeparatorColor;
  
  [self.headerView addSubview:topBorder];
  
  UIView *bottomBorder = [[[UIView alloc] initWithFrame:CGRectMake(0, headerNewFrame.size.height, headerNewFrame.size.width, 1)] autorelease];
  bottomBorder.backgroundColor = kSeparatorColor;
  
  [self.headerView addSubview:bottomBorder];
}

- (void) setupNoCommentsYetLabel
{
  if(self.noCommentsYetLabel == nil){
    self.noCommentsYetLabel = [[UILabel alloc] init];
    self.noCommentsYetLabel.frame = CGRectMake(0, self.headerView.frame.size.height + 50, self.headerView.frame.size.width,  20);
    self.noCommentsYetLabel.textColor = self.commentsLabel.textColor = self.FWConnection.mFWColorOfTextHeader;
    self.noCommentsYetLabel.textAlignment = NSTextAlignmentCenter;
    self.noCommentsYetLabel.font = [UIFont systemFontOfSize:16];
    self.noCommentsYetLabel.text = NSBundleLocalizedString(@"mFW_noMessagesYetString", @"No messages yet");
    self.noCommentsYetLabel.backgroundColor = [UIColor clearColor];
  
    [self.headerView addSubview:self.noCommentsYetLabel];
    [self.noCommentsYetLabel release];
  }
}

- (void)showImageWithURL:(NSURL*)url caption:(NSString*)caption description:(NSString*)description
{
  
  [self.FWConnection.mFWLargeImagesForBrowsingFromPreviews removeAllObjects];
  
  MWPhoto *photo;
  photo = [MWPhoto photoWithURL:url];
  photo.caption = caption;
  photo.description = description;
  [self.FWConnection.mFWLargeImagesForBrowsingFromPreviews addObject:photo];
  
  mFWPhotoBrowser *browser = [[[mFWPhotoBrowser alloc] initWithDelegate:self] autorelease];
  browser.displayActionButton  = YES;
  browser.bSavePicture         = YES;
  browser.leftBarButtonCaption = NSLocalizedString(@"mFW_commentsPageTitle", @"Comments");
  [browser setInitialPageIndex:0];
  
  [self.navigationController pushViewController:browser animated:YES];
}

- (void)showHeaderViewAttachedImage
{
  [self showImageWithURL:[NSURL URLWithString:[[[self.r1firstPost objectForKey:@"images"] objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                 caption:[NSBundleLocalizedString(@"mFW_postedByPhotoCaption", @"Posted by ") stringByAppendingString:[self.r1firstPost objectForKey:@"user_name"]]
             description:[self.r1firstPost objectForKey:@"text"]];
}


- (void)showAttachedImage:(UIGestureRecognizer *)recognizer
{
  NSIndexPath *swipedIndexPath = [self.replies indexPathForRowAtPoint:[recognizer locationInView:self.replies]];
  
  [self showImageWithURL:[NSURL URLWithString:[[[[self.rep1Posts objectAtIndex:swipedIndexPath.row] objectForKey:@"images"] objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                 caption:[NSBundleLocalizedString(@"mFW_postedByPhotoCaption", @"Posted by ") stringByAppendingString:[[self.rep1Posts objectAtIndex:swipedIndexPath.row] objectForKey:@"user_name"]]
             description:[[self.rep1Posts objectAtIndex:swipedIndexPath.row] objectForKey:@"text"]];
}

- (void)showUserProfile:(UIGestureRecognizer *)recognizer
{
  if ( self.hostStatus == NotReachable )
    return;
  
  NSIndexPath *swipedIndexPath = [self.replies indexPathForRowAtPoint:[recognizer locationInView:self.replies]];
  
  mFWProfile *mFWProfileView = [[[mFWProfile alloc] init] autorelease];
  
  if(swipedIndexPath == nil){ // tapped on header avatar, not on comment in table view
    mFWProfileView.avatarURL   = [self.r1firstPost objectForKey:@"user_avatar"];
    mFWProfileView.userName    = [self.r1firstPost objectForKey:@"user_name"];
    mFWProfileView.accountType = [self.r1firstPost  objectForKey:@"account_type"];
    mFWProfileView.accountID   = [self.r1firstPost  objectForKey:@"account_id"];
  } else {
    mFWProfileView.avatarURL   = [[self.rep1Posts objectAtIndex:swipedIndexPath.row] objectForKey:@"user_avatar"];
    mFWProfileView.userName    = [[self.rep1Posts objectAtIndex:swipedIndexPath.row] objectForKey:@"user_name"];
    mFWProfileView.accountType = [[self.rep1Posts objectAtIndex:swipedIndexPath.row] objectForKey:@"account_type"];
    mFWProfileView.accountID   = [[self.rep1Posts objectAtIndex:swipedIndexPath.row] objectForKey:@"account_id"];
  }
  
  [self.FWConnection showIndicatorWithCenter:CGPointMake(self.view.frame.size.width  / 2.f,
                                                         self.view.frame.size.height / 2.f)
                                      inView:self.view];
  
  self.view.userInteractionEnabled = NO;
  self.navigationController.navigationBar.userInteractionEnabled = NO;
  
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
                                                  [self.navigationController pushViewController:mFWProfileView animated:YES];
                                                }];
}

- (void)showComments:(UIGestureRecognizer *)recognizer
{
  NSIndexPath *swipedIndexPath = [self.replies indexPathForRowAtPoint:[recognizer locationInView:self.replies]];
  [self showCommentsAtIndex:swipedIndexPath.row];
  
}

- (void)showCommentsAtIndex:(NSInteger)index
{
  mFWReplies *mFWReplies2VC = [[mFWReplies alloc] init];
  
  mFWReplies2VC.r1firstPost = [self.rep1Posts objectAtIndex:index];
  mFWReplies2VC.r1replyID   = [[self.rep1Posts objectAtIndex:index] objectForKey:@"post_id"];
  mFWReplies2VC.r1parentID  = [[self.rep1Posts objectAtIndex:index] objectForKey:@"parent_id"];
  
  self.FWConnection.requiresRequest = YES;
  mFWReplies2VC.firstTimeLoad = YES;
  
  [self.navigationController pushViewController:mFWReplies2VC animated:YES];
  [mFWReplies2VC release];
}

- (void)goToPost
{
  authenticationRequestSource = PostScreen;
  [self authenticateWithAsha];
}

-(void)setRep1Posts:(NSMutableArray *)rep1Posts_
{
  if (!rep1Posts_)
  {
    if (!_rep1Posts)
      return;
    {
      [_rep1Posts release];
      _rep1Posts = nil;
      return;
    }
  }
  
  if ( _rep1Posts != rep1Posts_ )
  {
    [_rep1Posts release];
    _rep1Posts = [rep1Posts_ retain];
  }
}

- (void) updateCommentsLabel
{
  NSNumber *commentsCount = [NSNumber numberWithUnsignedInteger:self.rep1Posts.count];
  
  if([commentsCount integerValue] > [self.commentsLabel.text integerValue]){
    self.commentsLabel.text = [NSString stringWithFormat:SLBundlePluralizedString(@"mFW_proflie_%@ comments", commentsCount, nil), commentsCount];
  }
}

- (void) updateCommentsLabelByValueOf:(NSUInteger)newPostsCount
{
  NSNumber *commentsCount = [NSNumber numberWithUnsignedInteger: (newPostsCount + [self.commentsLabel.text integerValue])];
  self.commentsLabel.text = [NSString stringWithFormat:SLBundlePluralizedString(@"mFW_proflie_%@ comments", commentsCount, nil), commentsCount];
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.rep1Posts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *ReplyCell1   = @"ReplyCell1";
  NSDictionary *currentPostDict = [self.rep1Posts objectAtIndex:indexPath.row];
  
  CGFloat currentHeight = 0;
  
  
  mFWRepliesCell *cell = (mFWRepliesCell *)[tableView dequeueReusableCellWithIdentifier:ReplyCell1];
  
  if ( cell == nil )
  {
    cell = [[[mFWRepliesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReplyCell1] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UITapGestureRecognizer *avatarImageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
    avatarImageTap.delegate = self;
    [cell.imageView addGestureRecognizer:avatarImageTap];
    [avatarImageTap release];
    
    UITapGestureRecognizer *textLabelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserProfile:)];
    textLabelTap.delegate = self;
    [cell.textLabel addGestureRecognizer:textLabelTap];
    
    UITapGestureRecognizer *attachedImageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttachedImage:)];
    attachedImageTap.delegate = self;
    [cell.attachedImageView addGestureRecognizer:attachedImageTap];
    [attachedImageTap release];
  }
  
    // AVATAR
  if ( [[currentPostDict objectForKey:@"user_avatar"] length] )
  {
    SDWebImageSuccessBlock fadeInBlock = ^(UIImage *image, BOOL cached)
    {
      if(!cached){
        cell.imageView.alpha = 0.0f;
        [UIView animateWithDuration:kFadeInDuration animations:^{
          cell.imageView.alpha = 1.0f;
        }];
      }
    };
    
    [cell.imageView setImageWithURL:[NSURL URLWithString:[[currentPostDict objectForKey:@"user_avatar"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                   placeholderImage: [UIImage imageNamed:resourceFromBundle(@"_mFW_big_ava")]
                           success:fadeInBlock
                           failure:nil];
    
    [fadeInBlock release];
  }
  else
  {
    cell.imageView.image = [UIImage imageNamed:resourceFromBundle(@"_mFW_small_ava")];
  }

    //--------------
  
  
    // TITLE
  cell.textLabel.text = [currentPostDict objectForKey:@"user_name"];
  cell.textLabel.textColor = self.FWConnection.mFWColorOfTextHeader;
  
  cell.textLabel.textAlignment = NSTextAlignmentLeft;
  cell.textLabel.font = [UIFont boldSystemFontOfSize:13.0f];
  cell.textLabel.frame = CGRectMake(kLeftMargin*2 + kLogoWidth, kTopMargin, cell.contentView.bounds.size.width - (kLeftMargin*3 + kLogoWidth), 15);
  cell.textLabel.userInteractionEnabled = YES;
  
  CGSize textLabelSize = [cell.textLabel.text sizeForFont:cell.textLabel.font
                                                limitSize:cell.textLabel.frame.size
                                          nslineBreakMode:cell.textLabel.lineBreakMode];
  
  cell.textLabel.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.textLabel.frame.origin.y, textLabelSize.width, textLabelSize.height);

    //--------------
  
  currentHeight = kCellMessageLabelMargin;
  
  
    // DATEDIFF
  CGFloat dateLabelWidth = cell.contentView.bounds.size.width - CGRectGetMaxX(cell.textLabel.frame) - 2 * kLeftMargin;
  
  cell.dateDiffLabel.frame = CGRectMake(cell.textLabel.frame.origin.x + textLabelSize.width + kLeftMargin,
                                        cell.textLabel.frame.origin.y,
                                        dateLabelWidth,
                                        textLabelSize.height);
  
  cell.dateDiffLabel.font = [UIFont systemFontOfSize:13.f];
  cell.dateDiffLabel.textColor = self.FWConnection.mFWColorOfTextHeader;
  cell.dateDiffLabel.alpha = 0.5f;
  cell.dateDiffLabel.backgroundColor = [UIColor clearColor];
  
  NSString *dateString = [currentPostDict objectForKey:@"create"];
  double dateDouble = dateString.doubleValue/1000;
  
  NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:dateDouble];
  NSString *dateDiff = [mFWSettings dateDiffForDate:postDate];
  cell.dateDiffLabel.text = [dateDiff isEqualToString:@"(null)" ] ? NSBundleLocalizedString(@"mFW_dateDiffJustNow", @"Just now") : dateDiff;
  
  
  
    // MESSAGE
  if ( [[currentPostDict objectForKey:@"text"] length] )
  {
    cell.messageLabel.hidden = NO;
    cell.messageLabel.backgroundColor = [UIColor clearColor];
    cell.messageLabel.numberOfLines = 0;
    cell.messageLabel.font = [UIFont systemFontOfSize:kCellMessageLabelFontSize];
    cell.messageLabel.textColor = self.FWConnection.mFWColorOfText;
    
    cell.messageLabel.text = [currentPostDict objectForKey:@"text"];
    
    CGSize messageLabelSize = [cell.messageLabel.text sizeForFont:cell.messageLabel.font
                                                        limitSize:CGSizeMake(cell.contentView.bounds.size.width - (3*kLeftMargin + kLogoWidth), 500.0f)
                                                  nslineBreakMode:cell.messageLabel.lineBreakMode];
    
    cell.messageLabel.frame = CGRectMake(2*kLeftMargin + kLogoWidth, kCellMessageLabelMargin, messageLabelSize.width, (NSInteger)messageLabelSize.height);
    currentHeight = cell.messageLabel.frame.origin.y + cell.messageLabel.frame.size.height + 5.0f;
    if (messageLabelSize.height < 25) {
      if(! [[currentPostDict objectForKey:@"thumbs"] count] ){
        currentHeight += kSpaceBetweenSeparatorAndNextCell;
      }
    }
  } else {
    currentHeight += 5;
    
    if(cell.messageLabel && !cell.messageLabel.hidden){
      cell.messageLabel.hidden = YES;
    }
  }
  
    // ATTACHED IMAGE THUMBNAIL
  if ( [[currentPostDict objectForKey:@"thumbs"] count] )
  {
    CGFloat imageWidth = self.replies.bounds.size.width - 3*kLeftMargin - kLogoWidth;
    
    cell.attachedImageView.frame = CGRectMake(2*kLeftMargin + kLogoWidth, currentHeight, imageWidth,  kCellAttachedImageViewHeight);
    
    cell.phImageView.frame = CGRectMake(kCellAttachedImageBorder, kCellAttachedImageBorder, imageWidth - 2*kCellAttachedImageBorder, kCellAttachedImageViewHeight - 2*kCellAttachedImageBorder);
    
    SDWebImageSuccessBlock fadeInBlock = ^(UIImage *image, BOOL cached)
    {
      if(!cached){
        cell.phImageView.alpha = 0.0f;
        [UIView animateWithDuration:kFadeInDuration animations:^{
          cell.phImageView.alpha = 1.0f;
        }];
      }
    };
    
    [cell.phImageView setImageWithURL:[NSURL URLWithString:[[[currentPostDict objectForKey:@"thumbs"] objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                     placeholderImage:self.placeholderImage
                              success:fadeInBlock
                              failure:nil];
    
    [fadeInBlock release];
    
    
    
    cell.phImageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.phImageView.clipsToBounds = YES;
    
    currentHeight += cell.attachedImageView.bounds.origin.y + cell.attachedImageView.bounds.size.height;
    
    currentHeight += kSpaceBetweenSeparatorAndNextCell;
  }
  else
  {
    cell.attachedImageView.frame = CGRectZero;
    cell.phImageView.frame = CGRectZero;
  }
  
  {
    //Text is not lower than avatar
    if(currentHeight <= kLogoHeight + kTopMargin){
      currentHeight += kCellEmptyCommentsSpaceBig;
    } else {
      //currentHeight += kCellEmptyCommentsSpaceSmall;
    }
  }
    // SEPARATOR
  cell.separatorLine.frame = CGRectMake(2*kLeftMargin + kLogoWidth, currentHeight - 1, cell.contentView.bounds.size.width - (2*kLeftMargin + kLogoWidth), 1);
  
  if (indexPath.row == (self.rep1Posts.count - 1))
    cell.separatorLine.backgroundColor = [UIColor clearColor];
  else {
    if(self.view.backgroundColor.isLight){
      cell.separatorLine.backgroundColor = kSeparatorColorForWhiteBackground;
    } else {
      cell.separatorLine.backgroundColor = kSeparatorColor;
    }
  }
  return cell;
}



#pragma mark -
#pragma mark UITableViewDelegate
- (CGFloat)tableView:textLabeltableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSDictionary *currentPostDict = [self.rep1Posts objectAtIndex:indexPath.row];
  
  float result = kCellMessageLabelMargin;
  
    // adding message height
  if ( [[currentPostDict objectForKey:@"text"] length] )
  {
    CGSize messageLabelSize = [[currentPostDict objectForKey:@"text"] sizeForFont:[UIFont systemFontOfSize:kCellMessageLabelFontSize]
                                                                        limitSize:CGSizeMake(self.view.bounds.size.width - (3*kLeftMargin + kLogoWidth), 500.0f)
                                                                  nslineBreakMode:NSLineBreakByWordWrapping];
    result += messageLabelSize.height + 5.0f;
    
    if(messageLabelSize.height > 25 && ![[currentPostDict objectForKey:@"thumbs"] count]){
      result -= kSpaceBetweenSeparatorAndNextCell;
    }
  } else {
    result += 5.0f;
  }
    // adding image height
  if ( [[currentPostDict objectForKey:@"thumbs"] count] )
    result += kCellAttachedImageViewHeight;

  if(self.isFirstLevelComment){
    // adding comments button height
    //result += kCellCommentsLabelHeight;
  }  else {
    //Text is not lower than avatar
    if(result <= kLogoHeight + kTopMargin){
      result += kCellEmptyCommentsSpaceBig;
    } else {
      result += kCellEmptyCommentsSpaceSmall;
    }
  }

  return result + kSpaceBetweenSeparatorAndNextCell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // allow opening comment detail page only for fisrst level
  if (self.r1replyID && [self.r1replyID isEqualToString:@"0"])
    [self showCommentsAtIndex:indexPath.row];
}



#pragma mark -
#pragma mark MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
  if(self.FWConnection.mFWLargeImagesForBrowsingFromPreviews){
    
    return self.FWConnection.mFWLargeImagesForBrowsingFromPreviews.count;
    
  }
  return 0;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
  if ( index < self.FWConnection.mFWLargeImagesForBrowsingFromPreviews.count )
    return [self.FWConnection.mFWLargeImagesForBrowsingFromPreviews objectAtIndex:index];
  return nil;
}

#pragma mark -
#pragma mark Reachability
- (void) reachabilityChanged: (NSNotification* )notification
{
  self.hostStatus = [[notification object] currentReachabilityStatus];
  if ( self.hostStatus == NotReachable )
  {
    self.reachable = NO;
  } else {
    self.reachable = YES;
  }
  [self.replies reloadData];
}

#pragma mark autorotate handlers
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

-(BOOL)shouldAutorotate
{
  return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

- (void) setupReplies
{
  CGRect repliesFrame = self.view.bounds;
  
  self.replies = [[[UITableView alloc] initWithFrame:repliesFrame
                                               style:UITableViewStylePlain] autorelease];
  
  self.replies.showsHorizontalScrollIndicator = NO;
  self.replies.showsVerticalScrollIndicator = NO;
  
  if(canEdit){
    UIEdgeInsets pulledUpInsets = self.replies.contentInset;
    pulledUpInsets.bottom = kInputToolbarInitialHeight;
    
    self.replies.contentInset = pulledUpInsets;
  }
  
  self.replies.tableHeaderView = self.headerView;
  self.replies.autoresizingMask    = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.replies.autoresizesSubviews = YES;
  self.replies.backgroundColor = [UIColor clearColor];
  self.replies.dataSource = self;
  self.replies.delegate = self;
  self.replies.separatorStyle = UITableViewCellSeparatorStyleNone;
  
  [self.view addSubview:self.replies];
  
  // EGORefreshTableHeaderView initialization
  self.reloading = NO;
  self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f,
                                                                                        0.0f - self.replies.frame.size.height,
                                                                                        self.replies.bounds.size.width,
                                                                                        self.replies.frame.size.height)] autorelease];

  self.refreshHeaderView.delegate = self;
  
  [self.replies addSubview:self.refreshHeaderView];
  //  update the last update date
	[self.refreshHeaderView refreshLastUpdatedDate];
  
  UITapGestureRecognizer *keyboardHider = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardOnTapOutside)];
  [self.replies addGestureRecognizer:keyboardHider];
  [keyboardHider release];
}

- (void) hideKeyboardOnTapOutside
{
  
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    dispatch_after(DISPATCH_TIME_NOW, GCDMainThread, ^{
        
    });
  self.reloading = YES;
	[self loadNewerReplies];
}
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return self.reloading; // should return if data source model is reloading
}
- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [NSDate date]; // should return date data source was last changed
}

- (void) doneLoadingPosts
{
  {
    if(self.reloading){ // we were uptading with EGO pull to refresh
      self.reloading = NO;
      [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.replies];
    } else {
      [self.FWConnection hideIndicator];
    }
    self.FWConnection.requiresRequest = NO;
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    [self.replies reloadData];
  };
}

#pragma mark -
- (void)loadRepliesWithCount:(NSInteger)count
             loadingStrategy:(RepliesLoadingStrategy) strategy
{
  self.s_rep1Posts = [[[[[[NSUserDefaults standardUserDefaults] objectForKey:@"s_rep1Posts"] objectForKey:self.r1parentID] objectForKey:self.r1replyID] mutableCopy] autorelease];
  if ( !self.s_rep1Posts )
  {
    self.s_rep1Posts = [[[NSMutableArray array] mutableCopy] autorelease];
  }
  
  if ( ( self.FWConnection.requiresRequest ) ||
      ( self.FWConnection.afterReply ) )
  {
    self.FWConnection.afterReply = NO;
    
    if(!self.reloading)
    {
      [self.FWConnection showIndicatorWithCenter:CGPointMake(self.view.frame.size.width / 2.f,
                                                             self.view.frame.size.height / 2.f)
                                          inView:self.view];
    }
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    
    self.hostReachable = [Reachability reachabilityWithHostName:[functionLibrary hostNameFromString:[ [NSString stringWithFormat:@"http://%@", appIBuildAppHostName()]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    self.hostStatus = [self.hostReachable currentReachabilityStatus];
    
    typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
    TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
    {
      NSUInteger postsCount = [[response objectForKey:@"posts"] count];
      
      if((strategy == LoadOlderReplies || strategy == LoadRepliesAtStart) && postsCount < count){
        //if (strategy == LoadRepliesAtStart) -- we have loaded first n replies an there are m replies, m < n
        // so we do not need to load older, because there are no older replies
        
        //mark that we've reached the bottom and there is no more need
        //to show download indicator when pulling the wall up to load older posts
        //(because there are no older posts)
        mayLoadOlderPosts = NO;
      }
      
      if(strategy == LoadRepliesAtStart){
        if (canEdit)
        {
          [self inputToolbarInit];
        }
      }
      if ( ( postsCount > 0 ) && ( self.hostStatus != NotReachable ) )
      {
        
        NSMutableArray *posts = [response objectForKey:@"posts"];
        
        switch(strategy){
          case LoadNewerReplies:
            if([posts count] > 0){
              for(NSDictionary *newPost in posts)
              {
                NSString *newPostId = [newPost objectForKey:@"post_id"];
                for(NSDictionary *oldPost in self.rep1Posts)
                {
                  NSString *oldPostId = [oldPost objectForKey:@"post_id"];
                  if([oldPostId isEqualToString:newPostId]){
                    goto postAlreadyExistsDoNotAddItOnceAgain;
                  }
                }
                [self.rep1Posts insertObjects:posts atIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, posts.count)]];
              postAlreadyExistsDoNotAddItOnceAgain:;
              }
            }
            [self updateCommentsLabelByValueOf:posts.count];
            break;
          case LoadOlderReplies:
            [self.rep1Posts addObjectsFromArray:posts];
            break;
          case LoadRepliesAtStart:
            if(self.rep1Posts.count <= posts.count){
              self.rep1Posts = posts;
            } else {
              [self.rep1Posts replaceObjectsInRange:NSMakeRange(0, posts.count - 1) withObjectsFromArray:posts];
            }
            [self updateCommentsLabel];
            break;
          default:
            break;
        }
        
        /*
        self.rep1Posts = [response objectForKey:@"posts"];
        
        [self.rep1Posts insertObjects:nil atIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, 1)]]; */
        
        NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
        if ( [[[NSUserDefaults standardUserDefaults] objectForKey:@"s_rep1Posts"] count] )
          tmpDictionary = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"s_rep1Posts"] mutableCopy] autorelease];
        
        NSMutableDictionary *D1 = [NSMutableDictionary dictionaryWithObject:[[self.rep1Posts copy] autorelease] forKey:self.r1replyID];
        NSMutableDictionary *D2 = [NSMutableDictionary dictionaryWithObject:[[D1 copy] autorelease] forKey:self.r1parentID];
        
        [tmpDictionary addEntriesFromDictionary:[[D2 copy] autorelease]];
        
        [[NSUserDefaults standardUserDefaults] setObject:[[tmpDictionary copy] autorelease]
                                                  forKey:@"s_rep1Posts"];
        
        [tmpDictionary removeAllObjects];
        
        if ( [posts count] > 0 )
        {
          self.lastPostID = [[self.rep1Posts objectAtIndex:0] objectForKey:@"post_id"];
          self.firstPostID = [[self.rep1Posts lastObject] objectForKey:@"post_id"];
        }
      }
      if(self.rep1Posts.count == 0){
        [self setupNoCommentsYetLabel];
      }
      else {
        if(self.noCommentsYetLabel){
          [self.noCommentsYetLabel removeFromSuperview];
        }
      }
      
      //      (self.rep1Posts.count == 2) ? (self.onePost = YES) : (self.onePost = NO);
      [self.replies reloadData];
      
      if(!self.reloading)
      {
        [self.FWConnection hideIndicator];
      } else {
        self.reloading = NO;
        [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.replies];
      }

      self.view.userInteractionEnabled = YES;
      self.navigationController.navigationBar.userInteractionEnabled = YES;
    };
    
    if ( self.hostStatus == NotReachable )
    {
      self.rep1Posts = self.s_rep1Posts;
      completionBlock(nil, nil, nil);
    } else {
      
      NSString *postID = @"0";
      NSString *replyID = @"0";
      /*
       * Checking if we are loading comments to coments
       */
      if(self.r1replyID != nil && [self.r1replyID intValue] != 0){
        replyID = self.r1replyID;
      } else {
        replyID = @"0";
      }
      
      switch (strategy) {
        case LoadNewerReplies:
          postID = self.lastPostID ? self.lastPostID : @"0";
          break;
        case LoadOlderReplies:
          postID = self.firstPostID ? self.firstPostID : @"0";
          count = -count;
          break;
        case LoadRepliesAtStart:
          break;
        default:
          break;
      }

      [self.FWConnection getMessagesWithParentID:self.r1parentID
                                      andReplyID:replyID
                                       andPostID:postID
                                           limit:count
                                         success:^(NSData *result, NSDictionary *response) {
                                           completionBlock(result, response, nil);
                                         }
                                         failure:^(NSError *error) {
                                           completionBlock( nil, nil, error);
                                         }];
    }
  }
}

- (void) loadRepliesAtStart
{
  [self loadRepliesWithCount:kDefaultCommentsCount loadingStrategy:LoadRepliesAtStart];
}

- (void) loadNewerReplies
{
  if(mayLoadNewerReplies)
  {
    [self loadRepliesWithCount:kMessagesNoLimit loadingStrategy:LoadNewerReplies];
  } else {
    mayLoadNewerReplies = YES;
  }
}

- (void) loadOlderReplies
{
  [self loadRepliesWithCount:kDefaultCommentsCount loadingStrategy:LoadOlderReplies];
}


#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
  
  float offset;
  if ( scrollView.contentSize.height < scrollView.bounds.size.height )
  {
    offset = 1.0f;
  }
  else
  {
    offset = scrollView.contentSize.height - scrollView.bounds.size.height;
  }
  // loading older posts with old approach
  // 1.0f - overscroll threshold to trigger loading older posts
  if ( scrollView.contentOffset.y == offset + scrollView.contentInset.bottom + 1.0f)
  {
    if(mayLoadOlderPosts){
      [self loadOlderReplies];
    }
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
	[self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void) authenticateWithAsha
{
  auth_ShareLoginVC *loginVC = [[auth_ShareLoginVC alloc] init];
  
  loginVC.messageText = enteredText;
  loginVC.attach = replyImages;
  
  loginVC.messageKey = kFWMessagePostTextKey;
  loginVC.attachKey = kFWMessagePostImagesKey;
  
  loginVC.notificationName = kAshaFWNewReply;
  loginVC.appID = self.FWConnection.mFWAppID;
  loginVC.moduleID = self.FWConnection.mFWModuleID;
  
  UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:loginVC] autorelease];
  navController.modalPresentationStyle = UIModalPresentationFormSheet;
  
  navController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
  navController.navigationBar.translucent = self.navigationController.navigationBar.translucent;
  navController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
  
#ifdef __IPHONE_7_0
  if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
    navController.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
  navController.navigationBar.titleTextAttributes = self.navigationController.navigationBar.titleTextAttributes;
#endif
  
  [self.navigationController presentViewController:navController animated:YES completion:nil];
  
  [loginVC release];
}

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
  
  self.inputToolbar = [[[mFWInputToolbar alloc] initWithFrame:inputToolbarFrame andManagingController:self] autorelease];
  self.inputToolbar.backgroundColor = kInputToolBarColor;
  [self.FWConnection refreshInputToolbarGeolocationIndicator:self.inputToolbar];
  
  self.inputToolbar.inputToolbarDelegate = self;
  self.inputToolbar.notificationName = kAshaFWNewReply;
  
  self.inputToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  
  [self.view addSubview:self.inputToolbar];
}

- (void)handleMessagePosting:(NSNotification *)notification
{
  if([notification.name isEqualToString:kAshaFWNewReply]){
    if ( aSha.user.authentificatedWith != auth_ShareServiceTypeNone ) {
      if(authenticationRequestSource == PostScreen){
        authenticationRequestSource = None;
        [self performSelector:@selector(goToPost) withObject:nil afterDelay:1.0f];
        return;
      }
    }
    
    enteredText = [[notification userInfo] objectForKey:kFWMessagePostTextKey];
    replyImages = [[notification userInfo] objectForKey:kFWMessagePostImagesKey];
    
    replyImages = [replyImages isEqual:[NSNull null]] ? nil : replyImages;
    enteredText = [enteredText isEqual:[NSNull null]] ? nil : enteredText;
    
    if([self.view viewWithTag:kInputToolbarMaskViewTag])
    {
      [[self.view viewWithTag:kInputToolbarMaskViewTag] removeFromSuperview];
    }
    
    if (enteredText.length || replyImages.count)
    {
      if ( aSha.user.authentificatedWith != auth_ShareServiceTypeNone )
      {
        if(authenticationRequestSource == BottomBar){
          authenticationRequestSource = None;
          
          [self performSelector:@selector(postReply) withObject:nil afterDelay:0.5f];
          return;
        } else {
          [self postReply];
        }
      } else {
        authenticationRequestSource = BottomBar;
        mayLoadNewerReplies = NO;
        [self authenticateWithAsha];
      }
    }
  }
}

- (void)postReply
{
  if(!replyImages.count && enteredText.length == 0){
    return;
  }
  
    [self.inputToolbar.textView resignFirstResponder];
    [self.FWConnection showIndicatorWithCenter:CGPointMake(self.view.frame.size.width  / 2.f,
                                                         self.view.frame.size.height / 2.f)
                                      inView:self.view];
    self.view.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
  
  typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
  TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
  {
    if ( [[response objectForKey:@"error"] length] )
    {
      UIAlertView *sendingErrorAlertView = [[[UIAlertView alloc] initWithTitle:@""
                                                                       message:NSBundleLocalizedString(@"mFW_postMessageFailedAlertMessage", @"Sending failed. Please try again")
                                                                      delegate:self
                                                             cancelButtonTitle:NSBundleLocalizedString(@"mFW_postMessageFailedAlertOkButtonTitle", @"OK")
                                                             otherButtonTitles:nil] autorelease];
      
      [sendingErrorAlertView show];
      
    } else {
      self.FWConnection.afterPost = YES;
      self.FWConnection.afterReply = YES;
      self.FWConnection.afterReply2 = YES;
      
      [self.inputToolbar clear];
      mayLoadNewerReplies = YES;
      [self loadNewerReplies];
    }
  };
  
  NSString *replyId = self.r1replyID.length  ? self.r1replyID : @"0";
  
  [self.FWConnection postMessageWithParentID:self.r1parentID
                                  andReplyID:replyId
                                    withText:enteredText
                                   andImages:replyImages
                                     success:^(NSData *result, NSDictionary *response) {
                                       completionBlock(result, response, nil);
                                     }
                                     failure:^(NSError *error) {
                                       completionBlock(nil, nil, error);
                                     }];
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
  
  frame.origin.y = self.view.frame.size.height - frame.size.height - keyboardFrame.size.height;
  
	self.inputToolbar.frame = frame;
	[UIView commitAnimations];
  keyboardIsVisible = YES;
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
  
  frame.origin.y = self.view.frame.size.height - frame.size.height;
  
	self.inputToolbar.frame = frame;
	[UIView commitAnimations];
  keyboardIsVisible = NO;
  
  if([self.view viewWithTag:kInputToolbarMaskViewTag]){
    [[self.view viewWithTag:kInputToolbarMaskViewTag] removeFromSuperview];
  }
}

- (void)showKeyboard
{
  CGRect maskViewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.inputToolbar.frame.origin.y);
  
  UIView *maskView = [[UIView alloc] initWithFrame:maskViewFrame];
  maskView.backgroundColor = [UIColor clearColor];
  
  maskView.tag = kInputToolbarMaskViewTag;
  
  UITapGestureRecognizer *maskViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
  maskViewTap.delegate = self;
  [maskView addGestureRecognizer:maskViewTap];
  [maskViewTap release];
  
  [self.view insertSubview:maskView belowSubview:self.inputToolbar];
  
  [maskView release];
}

- (void)hideKeyboard
{
  enteredText = [self.inputToolbar.textView.text copy];
  
  [[self.view viewWithTag:kInputToolbarMaskViewTag] removeFromSuperview];
  
  [self.inputToolbar.textView resignFirstResponder];
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

- (void)adjustWallToAuxiliaryToolbar:(NSNotification *)notification
{
  CGFloat insetBottom = [[notification.userInfo objectForKey:kAuxiliaryToolbarToggledHeightDiffNotificationKey] floatValue];
  
  UIEdgeInsets newWallInset = self.replies.contentInset;
  newWallInset.bottom += insetBottom;
  
  [UIView animateWithDuration:kAuxiliaryToolbarTogglingAnimationDuration animations:^{
    self.replies.contentInset = newWallInset;
  }];
}

-(void)refreshInputToolbarGeolocationIndicator
{
  [self.FWConnection refreshInputToolbarGeolocationIndicator:self.inputToolbar];
}

@end