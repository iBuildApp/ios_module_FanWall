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

#import "mFWPhotosVC.h"
#import "mFWSettings.h"
#import "mFWConnection.h"
#import "mFWPhotoBrowser.h"

#import <objc/runtime.h>

@interface mFWPhotosViewController ()
{
  UIBarButtonItem *backBarButton;
}

/**
 *  GridView for photo gallery thumbnails
 */
@property(nonatomic, strong) NRGridView     *gallery;

@end

@implementation mFWPhotosViewController

@synthesize fwSettings = _fwSettings;

- (id)init
{
  self = [super init];
  
  self.tabBarIsHidden = YES;
  self.showTabBar     = NO;
  self.FWConnection = nil;
  self.fwSettings   = nil;
  backBarButton = nil;
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  backBarButton = [[UIBarButtonItem alloc] init];
  backBarButton.title = self.navigationController.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"mFW_backToWallButtonTitle", @"Wall");
  
  [self createUI];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - View lifecycle

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
  
  [cell.imageView setImageWithURL:[NSURL URLWithString:[[[self.fwSettings.imageLinks objectAtIndex:indexPath.itemIndex] objectForKey:@"thumb"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                 placeholderImage:[UIImage imageNamed:@"photo_placeholder.png"]];
  
  return cell;
}

#pragma mark -
#pragma mark NRGridViewDelegate
- (void)gridView:(NRGridView *)gridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
  [self.gallery deselectCellAtIndexPath:indexPath animated:NO];
  
  [mFWConnection sharedInstance].activeImage = indexPath;
  
	mFWPhotoBrowser *browser = [[mFWPhotoBrowser alloc] initWithDelegate:self];
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
  return self.fwSettings.photos.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
  if ( index < self.fwSettings.photos.count )
    return [self.fwSettings.photos objectAtIndex:index];
  return nil;
}

#pragma mark -

- (void) createUI
{
  self.view.backgroundColor = self.FWConnection.mFWColorOfBackground;
  
  CGPoint center = (CGPoint){self.view.center.x, self.view.center.y - CGRectGetMaxY(self.navigationController.navigationBar.bounds)};
  
  [self.FWConnection showIndicatorWithCenter:center inView:self.view];
  
  self.view.userInteractionEnabled = NO;
  self.navigationController.navigationBar.userInteractionEnabled = NO;
  
  typedef void (^TCompletionBlock)(NSData *result, NSDictionary *response, NSError *error);
  TCompletionBlock completionBlock = ^void(NSData *result, NSDictionary *response, NSError *error)
  {
    if ( response && [response objectForKey:@"gallery"] && [[response objectForKey:@"gallery"] count] > 0 )
    {
      self.fwSettings.images = [NSMutableArray arrayWithArray:[response objectForKey:@"gallery"]];
      [[NSUserDefaults standardUserDefaults] setObject:self.fwSettings.images forKey:@"s_images"];
    }
    
    self.gallery = [[NRGridView alloc] initWithFrame:CGRectMake(0.0f,
                                                                 10.0f,
                                                                 self.view.frame.size.width,
                                                                 self.view.frame.size.height - 10.0f)];
    self.gallery.autoresizesSubviews = YES;
    self.gallery.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.gallery.dataSource = self;
    self.gallery.delegate = self;
    
    self.gallery.backgroundColor = self.FWConnection.mFWColorOfBackground;
    
    [self.gallery setCellSize:CGSizeMake(160.0f, 160.0f)];
    
    [self.fwSettings.imageLinks removeAllObjects];
    
    for ( int i = 0; i < self.fwSettings.images.count; i++ )
    {
      [self.fwSettings.imageLinks addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[[[[self.fwSettings.images objectAtIndex:i] objectForKey:@"thumbs"] objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"thumb", nil]];
    }
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    MWPhoto *photo;
    for ( int i = 0; i < self.fwSettings.images.count; i++ )
    {
      NSURL *photoURL = [NSURL URLWithString:[[[[self.fwSettings.images objectAtIndex:i] objectForKey:@"images"] objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
      
      const char *key = [kAttachedPostIdKey UTF8String];
      
      NSString *postId = self.fwSettings.images[i][@"post_id"];
      objc_setAssociatedObject(photoURL, key, postId, OBJC_ASSOCIATION_RETAIN);
      
      photo = [MWPhoto photoWithURL:photoURL];
      photo.caption = [NSBundleLocalizedString(@"mFW_postedByPhotoCaption", @"Posted by ") stringByAppendingString:[[self.fwSettings.images objectAtIndex:i] objectForKey:@"user_name"]];
      photo.description = [[self.fwSettings.images objectAtIndex:i] objectForKey:@"text"];
      
      [photos addObject:photo];
    }
    
    self.fwSettings.photos = photos;
    
    [self.view addSubview:self.gallery];
    [self.gallery reloadData];
    
    self.view.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    [self.FWConnection hideIndicator];
  };
    [self.FWConnection getGalleryWithSuccess:^(NSData *result, NSDictionary *response) {
      completionBlock( result, response, nil );
    } failure:^(NSError *error) {
      completionBlock( nil, nil, error );
    }];
}


- (void) dealloc
{
  if(backBarButton != nil){
    backBarButton = nil;
  }
}

@end
