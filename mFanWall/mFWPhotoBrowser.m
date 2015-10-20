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

#import "mFWPhotoBrowser.h"
#import "mFWConnection.h"
#import <objc/runtime.h>

@interface mFWPhotoBrowser ()
{
  auth_Share *aSha;
  mFWConnection *connection;
}

@property (nonatomic, retain) mFWConnection *FWConnection;

- (id<MWPhoto>)photoAtIndex:(NSUInteger)index;
- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo;

@end

@implementation mFWPhotoBrowser

#pragma mark - View lifecycle

-(void) viewDidLoad
{
  [super viewDidLoad];
  aSha = [auth_Share sharedInstance];
  aSha.messageProcessingBlock = nil;

  self.FWConnection = [mFWConnection sharedInstance];
  
  UITapGestureRecognizer *statusBarHider = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideStatusBar)] autorelease];
  statusBarHider.cancelsTouchesInView = NO;
  statusBarHider.numberOfTapsRequired = 1;
}

-(void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] init];
  backBarButton.title = self.navigationController.navigationItem.leftBarButtonItem.title = super.leftBarButtonCaption;
  self.navigationController.navigationBar.topItem.backBarButtonItem = backBarButton;
}

-(void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

#pragma mark -

- (void)showActionSelector
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
	  [actionSheet addButtonWithTitle:NSLocalizedString(@"general_sharingFacebookButtonTitle", @"Facebook")];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"general_sharingTwitterButtonTitle", @"Twitter")];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"core_photoBrowserSavePictureButton", @"Save picture")];
    
    if ( actionSheet.numberOfButtons > 0 )
    {
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"core_photoBrowserCancelButtonTitle", @"Cancel")];
        [actionSheet showInView:( self.tabBarController ? self.tabBarController.view : self.navigationController.view )];
    }
    [actionSheet release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
      [self performSelector:@selector(shareFacebook) withObject:nil afterDelay:0.3f];
    }
    else if(buttonIndex == 1)
    {
      [self performSelector:@selector(shareTwitter) withObject:nil afterDelay:0.3f];
    }
  
    else if ( buttonIndex == 2 )
    {
        id <MWPhoto>photo = [self photoAtIndex:_currentPageIndex];
        if ( photo.underlyingImage )
        {
            UIImageWriteToSavedPhotosAlbum( photo.underlyingImage,
                                           self,
                                           @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:),
                                           NULL );
        }
    }
}

-(void)shareFacebook {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  
  id <MWPhoto>photo = [self photoAtIndex:_currentPageIndex];

  [data setObject:@"/me/photos" forKey:@"graphPath"];

  NSMutableString *template = [NSMutableString stringWithFormat:
                               NSBundleLocalizedString(@"mFW_shareMessageTemplate", @"I just found this in the %@: "),
                               [mFWConnection sharedInstance].appName];
  
  NSMutableString *message;
  {
    message =  template;
  }
  
  NSString *url = ((MWPhoto *)photo).photoURL.absoluteString;
  if(url){
    [data setObject:url forKey:@"url"];
    [message appendFormat:@"%@", url];
  }
  
  [data setObject:message forKey:@"message"];
  
  aSha.viewController = self;
  aSha.delegate = self;
  [aSha shareContentUsingService:auth_ShareServiceTypeFacebook fromUser:aSha.user withData:data showLoginRequiredPrompt:NO];
}

-(void)shareTwitter {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  
  id <MWPhoto>photo = [self photoAtIndex:_currentPageIndex];
  UIImage *underlyingImage = photo.underlyingImage;
  
  if ( photo.underlyingImage )
  {
    [data setObject:underlyingImage forKey:@"image"];
  }
  
  aSha.viewController = self;
  aSha.delegate = self;
  [aSha shareContentUsingService:auth_ShareServiceTypeTwitter fromUser:aSha.user withData:data showLoginRequiredPrompt:NO];
}

#pragma mark - auth_ShareDelegate
- (void)didShareDataForService:(auth_ShareServiceType)serviceType error:(NSError *)error
{
  if (error)
  {
    NSLog(@"mFW Photo browser: doneSharingDataForService:withError: %@", [error localizedDescription]);
    return;
  }
  else
  {
    NSLog(@"mFW Photo browser: doneSharingDataForService:withError: completed!");
    
    MWPhoto *photo = (MWPhoto *)[self photoAtIndex:_currentPageIndex];
    
    const char *key = [kAttachedPostIdKey UTF8String];
    NSURL *URL = photo.photoURL;
    NSString *postId = objc_getAssociatedObject(URL, key);
    NSLog(@"mFW Photo browser: postId to increase: %@", postId);
    if(postId){
      [[NSNotificationCenter defaultCenter] postNotificationName:kmFWPhotoBrowserSucceededSharingNotificationName
                                                          object:nil
                                                        userInfo:@{ kmFWPhotoBrowserSucceededSharingURLKey : [URL absoluteString],
                                                                    kAttachedPostIdKey: postId}];
    } else {
      NSLog(@"mFW Photo browser: error! postId to increase id NIL!");
    }
  }
}

-(void)hideStatusBar
{
  if(![UIApplication sharedApplication].statusBarHidden){
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  } else {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
  }
}

-(NSString *)sharePictureSideBarActionLabel
{
  return NSBundleLocalizedString(@"mFW_photoBrowserSideBarSaveAction", @"Share");
}

-(void)dealloc
{
  aSha.delegate = nil;
  self.FWConnection = nil;
  [super dealloc];
}

@end
