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


#import "mFWProfile.h"
#import "mWebVC.h"
#import "appconfig.h"

#import <Smartling.i18n/SLLocalization.h>

@interface mFWProfile()
  @property(nonatomic, assign) BOOL tabBarIsHidden;
  @property(nonatomic, strong) mFWConnection  *FWConnection;
@end

@implementation mFWProfile

@synthesize avatarURL   = _avatarURL;
@synthesize userName    = _userName;
@synthesize accountID   = _accountID;
@synthesize accountType = _accountType;
@synthesize dateString  = _dateString;
@synthesize pCountText  = _pCountText;
@synthesize cCountText  = _cCountText;
@synthesize tabBarIsHidden;
@synthesize FWConnection = _FWConnection;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
    tabBarIsHidden = YES;
    _avatarURL   = nil;
    _userName    = nil;
    _accountID   = nil;
    _accountType = nil;
    _dateString  = nil;
    _pCountText  = nil;
    _cCountText  = nil;
    _FWConnection = nil;
  }
  return self;
}

- (void)dealloc
{
  self.avatarURL   = nil;
  self.userName    = nil;
  self.accountID   = nil;
  self.accountType = nil;
  self.dateString  = nil;
  self.pCountText  = nil;
  self.cCountText  = nil;
  self.FWConnection = nil;
  [super dealloc];
}

#pragma mark -
#pragma mark view life cycle
- (void)viewWillAppear:(BOOL)animated
{
  // hide tab bar
  self.tabBarIsHidden = [[self.tabBarController tabBar] isHidden];
  if ( !self.tabBarIsHidden )
    [[self.tabBarController tabBar] setHidden:YES];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [mFWConnection sharedInstance].requiresRequest = NO;

  // restore tab bar state
  [[self.tabBarController tabBar] setHidden:self.tabBarIsHidden];
  [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
  [self.navigationController setNavigationBarHidden:NO animated:NO];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  
  self.navigationItem.title = NSBundleLocalizedString(@"mFW_profilePageTitle", @"Profile");
  
  self.FWConnection = [mFWConnection sharedInstance];
  
  self.view.backgroundColor = self.FWConnection.mFWColorOfBackground;
  
  UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 80.0f, 80.0f)];
  
  if ( self.avatarURL.length )
  {
    [avatarImage setImageWithURL:[NSURL URLWithString:[self.avatarURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                placeholderImage:[UIImage imageNamed:@"photo_placeholder.png"]];
    avatarImage.contentMode = UIViewContentModeScaleAspectFill;
  } else {
    avatarImage.image = [UIImage imageNamed:resourceFromBundle(@"_mFW_ava_profile")];
  }
  
  avatarImage.layer.cornerRadius = 6.0f;
  avatarImage.layer.masksToBounds = YES;
  
  [self.view addSubview:avatarImage];
  [avatarImage release];
  
  UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(100.0f, 10.0f, 200.0f, 20.0f)];
  name.textAlignment   = NSTextAlignmentLeft;
  name.font            = [UIFont boldSystemFontOfSize:20.0f];
  name.backgroundColor = [UIColor clearColor];
  name.textColor       = self.FWConnection.mFWColorOfTextHeader;
  name.text            = self.userName;
  [self.view addSubview:name];
  [name release];
  
  
  double dateDouble = self.dateString.doubleValue/1000;
  NSDate *dateDate = [NSDate dateWithTimeIntervalSince1970:dateDouble];
  
  NSString *dateLabelText = [NSString stringWithFormat:@"%@: %@", NSBundleLocalizedString(@"mFW_lastMessageString", @"Last message"), [functionLibrary formatTimeInterval:dateDate]];
  UIFont *dateFont = [UIFont systemFontOfSize:16.0f];
  NSLineBreakMode dateBreakMode = NSLineBreakByWordWrapping;
  CGSize dateLabelSize = [dateLabelText sizeForFont:dateFont limitSize:(CGSize){200.0f, 200.0f} lineBreakMode:dateBreakMode];
  
  UILabel *date = [[UILabel alloc] initWithFrame:CGRectMake(100.0f, 33.0f, dateLabelSize.width, dateLabelSize.height)];
  date.textAlignment   = NSTextAlignmentLeft;
  date.font            = dateFont;
  date.backgroundColor = [UIColor clearColor];
  date.textColor       = self.FWConnection.mFWColorOfText;
  date.lineBreakMode   = dateBreakMode;
  date.numberOfLines   = 0;
  date.text = dateLabelText;
  
  [self.view addSubview:date];
  [date release];
  
  CGFloat pCountOriginY = date.frame.origin.y + date.frame.size.height + 1.0f;
  UILabel *pCount = [[UILabel alloc] initWithFrame:CGRectMake(100.0f, pCountOriginY, 150.0f, 18.0f)];
  pCount.textAlignment   = NSTextAlignmentLeft;
  pCount.font            = [UIFont systemFontOfSize:16.0f];
  pCount.backgroundColor = [UIColor clearColor];
  pCount.textColor       = self.FWConnection.mFWColorOfText;
  NSNumber *number = [NSNumber numberWithInteger:self.pCountText.integerValue];
  pCount.text = [NSString stringWithFormat:SLBundlePluralizedString(@"mFW_proflie_%@ posts", number, nil), number];
  [self.view addSubview:pCount];
  [pCount release];
  
  
  CGFloat cCountOriginY = pCount.frame.origin.y + pCount.frame.size.height + 1.0f;
  UILabel *cCount = [[UILabel alloc] initWithFrame:CGRectMake(100.0f, cCountOriginY, 150.0f, 18.0f)];
  cCount.textAlignment = NSTextAlignmentLeft;
  cCount.font = [UIFont systemFontOfSize:16.0f];
  cCount.backgroundColor = [UIColor clearColor];
  cCount.textColor = self.FWConnection.mFWColorOfText;
  number = [NSNumber numberWithInteger:self.cCountText.integerValue];
  cCount.text = [NSString stringWithFormat:SLBundlePluralizedString(@"mFW_proflie_%@ comments", number, nil), number];
  
  [self.view addSubview:cCount];
  [cCount release];
  
  CGFloat profileButtonOriginY = cCount.frame.origin.y + cCount.frame.size.height;// + 2.0f;
  UIButton *profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
  profileButton.frame = CGRectMake(100.0f, profileButtonOriginY, 200.0f, 40.0f);
  profileButton.layer.cornerRadius = 4.0f;
  profileButton.layer.masksToBounds = YES;
  [profileButton addTarget:self action:@selector(profileButtonClicked) forControlEvents:UIControlEventTouchUpInside];
  profileButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
  [profileButton setContentHorizontalAlignment: UIControlContentHorizontalAlignmentLeft];
  UIImage *profileIcon = [[[UIImage alloc] init] autorelease];
  if ( [self.accountType isEqualToString:@"facebook"] )
  {
    [profileButton setTitle:[@"      " stringByAppendingString:NSBundleLocalizedString(@"mFW_profileFacebookButtonTitle", @"Facebook")] forState:UIControlStateNormal];
    profileIcon = [UIImage imageNamed:resourceFromBundle(@"_mFW_facebook_icon")];
  }
  if ( [self.accountType isEqualToString:@"twitter"] )
  {
    [profileButton setTitle:[@"      " stringByAppendingString:NSBundleLocalizedString(@"mFW_profileTwitterButtonTitle", @"Twitter")] forState:UIControlStateNormal];
    profileIcon = [UIImage imageNamed:resourceFromBundle(@"_mFW_twitter_icon")];
  }
  if ( [self.accountType isEqualToString:@"ibuildapp"] ) // || (!self.accountType.length) )
  {
    [profileButton setTitle:[@"      " stringByAppendingString:NSBundleLocalizedString(@"mFW_profileiBuildAppButtonTitle", @"iBuildApp")] forState:UIControlStateNormal];
    profileIcon = [UIImage imageNamed:resourceFromBundle(@"_mFW_iba_icon")];
  }
  
  [profileButton setTitleColor:self.FWConnection.mFWColorOfTime
                      forState:UIControlStateNormal];
  
  UIImageView *profileIconView = [[UIImageView alloc] initWithImage:profileIcon];
  profileIconView.frame = CGRectMake(0.0f,
                                     (profileButton.frame.size.height - profileIcon.size.height) / 2.0f,
                                     profileIcon.size.width,
                                     profileIcon.size.height);
  [profileButton addSubview:profileIconView];
  [self.view addSubview:profileButton];
  [profileIconView release];
  
  [super viewDidLoad];
}

#pragma mark -
#pragma mark UIButton handlers
- (void)profileButtonClicked
{
  mWebVCViewController *mFWWeb = [[mWebVCViewController alloc] init];
  NSString *aURL = nil;
  if ( [self.accountType isEqualToString:@"facebook"] )
  {
    aURL = [NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@", self.accountID];
  }
  if ( [self.accountType isEqualToString:@"twitter"] )
  {
    aURL = [NSString stringWithFormat:@"https://twitter.com/intent/user?user_id=%@", self.accountID];
  }
  if ( ([self.accountType isEqualToString:@"ibuildapp"] ) || (!self.accountType.length) )
  {
    aURL = [NSString stringWithFormat:@"http://%@/members/%@", appIBuildAppHostName(), self.accountID];
    mFWWeb.scalable = YES;
    mFWWeb.webView.contentMode = UIViewContentModeScaleAspectFit;
  }
  if( !aURL.length )
    aURL = @"";
  
  mFWWeb.URL        = aURL;
  mFWWeb.showTabBar = NO;
  [self.navigationController pushViewController:mFWWeb animated:YES];
  [mFWWeb release];
}

#pragma mark autorotate handlers
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}

@end
