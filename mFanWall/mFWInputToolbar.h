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
#import "mFWExpandingTextView.h"
#import "mFWImageConsumer.h"

#define kIconsPadding  16.0f

#define kCloseAttachControlLeftMargin 6.0f
#define kSpaceBetweenGalleryIconAndTextView 10.0f

#define kPrimaryIconsWidthAndHeight  (25.0f + 2*kIconsPadding) // icon size for image picker and sender controls

#define kCloseAttachIconWidth 36.0f
#define kOtherAuxiliaryIconsWidth  40.0f //To make tap area bigger
#define kSpaceBetweenGalleryAndPhotoIcons  20.0f
#define kSpaceBetweenCloseAttachAndPhotoIcons  20.0f
#define kSpaceBetweenImages 15.0f

#define kInputToolBarColor  [UIColor colorWithRed:0.942f green:0.942f blue:0.942f alpha:1.0]

#define kFramePendingInitialization CGRectZero
#define kInputToolbarInitialHeight  52.0f

#define kInputToolbarMaskViewTag 12345

#define kInputToolbarExpandingTextViewInitialHeight 37.0f

#define kPreviewImageWidthAndHeight  50.0f
#define kPreviewImageLeftPadding     10.0f
#define kPreviewImageTopPadding       8.0f
#define kPreviewImageBottomPadding    5.0f
#define kPreviewPaneSpacerColor       [UIColor colorWithRed:0.902 green:0.902 blue:0.902 alpha:1.0f]
#define kPreviewPaneSpacerHeight      1.0f
#define kPreviewPaneHeight            (kPreviewImageTopPadding + kPreviewImageBottomPadding + kPreviewImageWidthAndHeight + kPreviewPaneSpacerHeight)

#define kBorderColor [UIColor colorWithWhite:0.0f alpha:0.2f]
#define kBorderHeight 1.0f

#define kRemovePreviewCrossShift 5.5f

#define kFirstPreviewToRemoveTag 7777

#define kAuxiliaryToolbarHeight                   40.0f
#define kAuxiliaryToolbarSpaceBetweenIconCenters 100.0f
#define kAuxiliaryToolbarTogglingAnimationDuration 0.3f

#define kAuxiliaryToolbarToggledNotificationName @"auxiliaryToolbarToggled"
#define kAuxiliaryToolbarToggledHeightDiffNotificationKey @"heightDiff"

extern NSString *const kFWMessagePostNotificationName;
extern NSString *const kFWMessagePostTextKey;
extern NSString *const kFWMessagePostImagesKey;

@class mFWInputToolbar;

/**
 * Delegate to handle tolbar-generated actions
 */
@protocol mFWInputToolbarDelegate <BHExpandingTextViewDelegate>
  /**
   * Handle location tracking turning on / off by tapping the appropriate toolbar control.
   *
   * @param toolbar - source toolbar of the action.
   */
  @required
  -(void)mFWInputToolbarDidToggleGeolocation:(mFWInputToolbar *)toolbar;
@end

@class mFWExpandingTextView;

/**
 * Toolbar to enter a message to post on the Wall.
 * Supports image picking and turning location tracking on / off.
 */
@interface mFWInputToolbar : UIToolbar <BHExpandingTextViewDelegate,
                                                   mFWImageConsumer>

/**
 * Custom (expandable) textView to enter a message.
 */
@property (nonatomic, strong) mFWExpandingTextView *textView;

/**
 * UIImageView as image picker launcher control. Tap on it makes image provider dialog appear
 */
@property (nonatomic, strong) UIImageView *imagePickerImageView;

/**
 * Gallery of picked images
 */
@property (nonatomic, strong) NSMutableArray *pickedImages;

/**
 * UIImageView as a "Send button". Tap on it sends composed message
 */
@property (nonatomic, strong) UIImageView *senderImageView;

/**
 * UIImageView as a "Pick image from gallery" button.
 */
@property (nonatomic, strong) UIImageView *pickFromGalleryImageView;

/**
 * UIImageView as a "Pick image by taking photo" button.
 */
@property (nonatomic, strong) UIImageView *takeAPhotoImageView;

/**
 * UIImageView as a "Location tracking on/off" button.
 */
@property (nonatomic, strong) UIImageView *toggleGeolocationImageView;

/**
 * Object that acts as a delegate for actions, triggered by the toolbar.
 */
@property (nonatomic, assign) id<mFWInputToolbarDelegate> inputToolbarDelegate;

/**
 * "Host" controller to present an image picking dialogue.
 */
@property (nonatomic, unsafe_unretained) UIViewController *managingController;

/**
 * Flag, telling whether picking of multiple images is supported.
 * If <code>NO</code>, a subsequently picked image replaces a previous one.
 */
@property  BOOL multiImageMode;

/**
 * Name for notification, published when user submits a valid message.
 * Valid message is either a message with text, or an image, or both.
 */
@property (nonatomic, strong) NSString *notificationName;

/**
 * Lower bar with camera, gallery, navigation controls
 */
@property (nonatomic, strong) UIView *auxiliaryToolbar;

/**
 * Initializes a new mFWInputToolbar instance with specified frame and a "host" controller
 * for image provider.
 *
 * @param frame - frame for the toolbar
 * @param managingController - "host" controller to present an image picking dialogue.
 */
-(id)initWithFrame:(CGRect)frame andManagingController:(UIViewController *)managingController;

/**
 * Clears text, removes picked images, hides the auxiliary toolbar.
 * @see auxiliaryToolbar
 */
-(void)clear;

/**
 * Height for inputToolbar with it's auxiliaryToolbar if present
 */
-(CGFloat)trueToolbarHeight;

/**
 * Highlights the "location tracking" control.
 *
 * @param isEnabled - if <code>YES</code> makes the corresponding icon blue. 
 * Otherwise sets it to default-gray.
 */
-(void)indicateGeolocationIsEnabled:(BOOL)isEnabled;

@end
