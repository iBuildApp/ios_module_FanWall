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
#import "mFWSocialButton.h"

#define kAvatarPaddingTop                      9.0f
#define kAvatarPaddingBottom                   9.0f
#define kMarginFromScreenEdges                10.0f
#define kPostContentsPaddingTop               10.0f
#define kPostContentsPaddingLeft              10.0f
#define kSpaceBetweenPostCells                10.0f
#define kPostCellWidth                        ([UIScreen mainScreen].bounds.size.width - 2*kMarginFromScreenEdges)

#define kAvatarImageViewBorderRadius          4.0f
#define kAvatarImageViewWidthAndHeight        36.0f

#define kBackgroundRoundedRectangleCornerRadius 2.0f  
#define kBackgroundRoundedRectangleBorderWidth  0.5f
#define kBackgroundRoundedRectangleBorderColor [UIColor colorWithWhite:0.0f alpha:0.2f].CGColor

#define kPostTextSize                         15.0f
#define kPostTextColor                        [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f]

/*#e9f4cd*/
#define kMyPostBackgroundColor                [UIColor colorWithRed:0.875 green:0.973 blue:0.797 alpha:1]
#define kOtherPostBackgroundColor             [UIColor colorWithWhite:1.0f alpha:1.0f]

/*#47a2ff*/
#define kCommentsLabelColor                   [UIColor colorWithRed:0.278 green:0.635 blue:1 alpha:1]
#define kCommentsLabelTextSize                13.0f
#define kSocialButtonHeight                   45.0f
#define kCommentsLabelTextPullupOffset        3.0f

#define kImageBorderWidth                     3.0f
#define kImageBorderColor                     [UIColor colorWithWhite:1.0f alpha:1.0f]
#define kImageBorderShadowColor               [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3]


#define kSpaceBetweenHorizontalSpacerAndPostMessage 12.0f
#define kPostMessagePullupOffset                    4.0f
#define kSpaceBetweenImageAndHorizontalSpacer       10.0f

#define kHorizontalSpacerColor                 [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f]
#define kHorizontalSpacerHeight                1.0f
#define kPostContentOffsetX                    (kPostContentsPaddingTop + kMarginFromScreenEdges)

#define kAttachedImageHeight                   160.0f

#define kSpaceBetweenPostTextAndAttachedImage  10.0f
#define kSpaceBetweenImageAndCommentsSpacer    15.0f

#define kUserNameLabelTextSize                 14.0f
#define kUserNameLabelTextColor                [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.9f]

#define kHoursAgoLabelTextSize                 12.0f
#define kHoursAgoLabelTextColor                [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f]

#define kSpaceBetweenImageAndTextLabels        7.0f

#define kMaxAllowedTextLabelWidth              200.0f


/**
 *  Customized UITableViewCell for FanWall posts tableView
 */
@interface mFWPostCell : UITableViewCell

/**
 * URL string for image being currently presented in cell.
 * Nil if image is hidden.
 */
@property (nonatomic, readonly, retain) NSString *attachedImageThumbnailURL;

#pragma mark Text labels

/**
 * Label with author user name.
 * By default, points to self.textLabel.
 */
@property (nonatomic, retain) UILabel *userNameLabel;

/**
 * Label with post's sending date.
 * By default, points to self.detailTextLabel.
 */
@property (nonatomic, retain) UILabel *postDateLabel;

/**
 * Label for post's message.
 */
@property (nonatomic, retain) UILabel *postMessageLabel;

#pragma mark Social buttons
/**
 * Button showing the number of comments. Tap on it leads to the comments page.
 *
 * @see mFWSocialButton
 */
@property (nonatomic, retain) mFWSocialButton *commentsButton;

/**
 * Button showing the number of facebook likes for image in post, 
 * is hidden for pure text posts.
 * Tap on it likes the image in the post.
 * Disabled when image in the post is already liked.
 *
 * @see mFWSocialButton
 */
@property (nonatomic, retain) mFWSocialButton *likesButton;

/**
 * Button showing the number shares for the image, both on twitter and facebook.
 * Tap on it presents dialog asking to choose sharing option - twitter or facebook.
 *
 * @see mFWSocialButton
 */
@property (nonatomic, retain) mFWSocialButton *sharesButton;


#pragma mark Misc views
/**
 * Backing view (with rounded corners) for a cell.
 */
@property (nonatomic, retain) UIView *backgroundRoundedRectangle;

/**
 * Separator line between user avatar, name, date and the rest of the cell.
 */
@property (nonatomic, retain) UIView *postContentsSpacer;

/**
 * White view with a shadow to lay attached image on.
 */
@property (nonatomic, retain) UIView *attachedThumbnailImageViewContainer;

/**
 * Image view for attached image.
 */
@property (nonatomic, retain) UIImageView *attachedThumbnailImageView;

/**
 * Image view for user's avatar.
 */
@property (nonatomic, retain) UIImageView *avatarImageView;

/**
 * Separator line between message (or image, if exists) and socialButtonsPane.
 *
 * @see socialButtonsPane
 */
@property (nonatomic, retain) UIView *commentsSpacer;

/**
 * Container for social buttons.
 *
 * @see commentsButton
 * @see likesButton
 * @see sharesButton
 */
@property (nonatomic, retain) UIView *socialButtonsPane;

/**
 * URL string for image being currently presented in cell.
 * Nil if image is hidden.
 */
-(NSString *) attachedImageThumbnailURL;

/**
 * Sets attached (main post) image with URL and placeholder image provided.
 *
 * @param URL - URL string to download an image.
 * @param placeholderImage - placeholder shown while image is fetching from URL or from cache.
 */
-(void)setAttachedImageThumbnailForURL:(NSString *)URL withPlaceholderImage:(UIImage *)placeholderImage;

/**
 * Sets user avatar image with URL and placeholder image provided.
 *
 * @param URL - URL string to download an avatar image.
 * @param placeholderImage - placeholder shown while image is fetching from URL or from cache.
 */
-(void)setAvatarImageForURL:(NSString *)URL withPlaceholderImage:(UIImage *)placeholderImage;

@end