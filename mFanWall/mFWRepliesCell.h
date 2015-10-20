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

#define kCellAttachedImageViewWidth 75.0f
#define kCellAttachedImageViewHeight 160.0f
#define kCellAttachedImageBorder 3.0f
#define kCellCommentsLabelHeight 25.f
#define kCellMessageLabelFontSize 13.f
#define kCellMessageLabelMargin 25.f

#define kCellEmptyCommentsSpaceBig 12.0f
#define kCellEmptyCommentsSpaceSmall 12.0f

/**
 *  Customized UITableViewCell for FanWall replies tableView
 */
@interface mFWRepliesCell : UITableViewCell

@property(nonatomic, strong) UILabel   *dateDiffLabel;
@property(nonatomic, strong) UILabel   *messageLabel;
@property(nonatomic, strong) UIView      *attachedImageView;
@property(nonatomic, strong) UIImageView *phImageView;
@property(nonatomic, strong) UILabel  *commentsLabel;
@property(nonatomic, strong) UIView   *separatorLine;



@end