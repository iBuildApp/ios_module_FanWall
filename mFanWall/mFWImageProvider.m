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

#import "mFWImageProvider.h"


@interface mFWImageProvider()

@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation mFWImageProvider

- (id) initWithImageConsumer:(id<mFWImageConsumer>)consumer andDialogPresenter:(UIViewController *)presenter;
{
  self = [super init];
  
  if(self){
    _actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                               delegate:self
                                      cancelButtonTitle:NSBundleLocalizedString(@"mFW_photoCancelButtomTitle", @"Cancel")
                                 destructiveButtonTitle:nil
                                      otherButtonTitles:NSBundleLocalizedString(@"mFW_takePhotoButtomTitle", @"Take Photo"),
                    NSBundleLocalizedString(@"mFW_choosePhotoButtomTitle", @"Choose Existing Photo"), nil];
    
    _imagePicker = nil;
    _imageConsumer = consumer;
    _presentingController = presenter;
  }
  
  return self;
}

- (void) displayDialog
{
  [self.actionSheet showInView:self.presentingController.view];
}

#pragma mark -
#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if ( buttonIndex == 0 )
  {
    self.imagePicker = [[UIImagePickerController alloc] init];
    BOOL cameraAvailable = [self setupImagePickerForCamera];
    
    if(!cameraAvailable){
      [self informNoCamera];
      return;
    }
  }
  else if ( buttonIndex == 1 )
  {
    self.imagePicker = [[UIImagePickerController alloc] init];
    if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] )
    {
      [self setupImagePickerForGallery];
    }
  } else {
    return;
  }
    [self performSelector:@selector(showPicker)
               withObject:self
               afterDelay:0.6f];
}

- (void) informNoCamera
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSBundleLocalizedString(@"mFW_noCameraTitle", @"No Camera Available")
                                                  message:NSBundleLocalizedString(@"mFW_noCameraMessage", @"Requires a camera to take pictures")
                                                 delegate:self
                                        cancelButtonTitle:NSBundleLocalizedString(@"mFW_noCameraOkButtonTitle", @"OK")
                                        otherButtonTitles:nil];
  [alert show];
  [alert release];
}


- (void) setupImagePickerForGallery
{
  self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  self.imagePicker.allowsEditing = NO;
  self.imagePicker.delegate = self;
}

- (BOOL) setupImagePickerForCamera
{
  BOOL cameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
  
  if(cameraAvailable){
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.allowsEditing = NO;
    self.imagePicker.delegate = self;
    self.imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
  }
  
  return cameraAvailable;
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  UIImage *tImage = [[info objectForKey:@"UIImagePickerControllerOriginalImage"] retain];
  
  if ( tImage.imageOrientation == UIImageOrientationRight )
    tImage = [UIImage imageWithCGImage:[self CGImageRotatedByAngle:tImage.CGImage angle:-90.0f]];
  else if ( tImage.imageOrientation == UIImageOrientationDown )
    tImage = [UIImage imageWithCGImage:[self CGImageRotatedByAngle:tImage.CGImage angle:180.0f]];
  else if ( tImage.imageOrientation == UIImageOrientationLeft )
    tImage = [UIImage imageWithCGImage:[self CGImageRotatedByAngle:tImage.CGImage angle: 90.0f]];
  
  [self.imageConsumer performSelector:@selector(imagePickedCallback:) withObject:tImage];
  
  [tImage release];
  
  [picker dismissModalViewControllerAnimated:YES];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
  });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [picker dismissModalViewControllerAnimated:YES];
  
  if([self.imageConsumer respondsToSelector:@selector(imagePickCancelledCallback)]){
    [self.imageConsumer performSelector:@selector(imagePickCancelledCallback)];
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
  });
}

#pragma mark - Image picking

- (void) provideAnImageFromGallery
{
  self.imagePicker = [[[UIImagePickerController alloc] init] autorelease];
  [self setupImagePickerForGallery];
  
  [self showPicker];
}

- (void) provideAnImageWithCamera
{
  self.imagePicker = [[[UIImagePickerController alloc] init] autorelease];
  if([self setupImagePickerForCamera]) {
  
  [self showPicker];
  } else {
    [self informNoCamera];
  }
}

- (void)showPicker
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.presentingController presentModalViewController:self.imagePicker animated:YES];
  });
}

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle
{
  CGFloat angleInRadians = angle * (M_PI / 180);
  CGFloat width = CGImageGetWidth(imgRef);
  CGFloat height = CGImageGetHeight(imgRef);
  
  CGRect imgRect = CGRectMake(0, 0, width, height);
  CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
  CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef bmContext = CGBitmapContextCreate(NULL,
                                                 rotatedRect.size.width,
                                                 rotatedRect.size.height,
                                                 8,
                                                 0,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
  CGContextSetAllowsAntialiasing(bmContext, YES);
  CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
  CGColorSpaceRelease(colorSpace);
  CGContextTranslateCTM(bmContext, + (rotatedRect.size.width / 2), + (rotatedRect.size.height / 2));
  CGContextRotateCTM(bmContext, angleInRadians);
  CGContextDrawImage(bmContext, CGRectMake(-width / 2, -height / 2, width, height), imgRef);
  
  CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
  CFRelease(bmContext);
  [(id)rotatedImage autorelease];
  
  return rotatedImage;
}

#pragma mark -

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
  });
}

- (void) dealloc
{
  self.imagePicker = nil;
  self.actionSheet = nil;
  
  [super dealloc];
}

@end
