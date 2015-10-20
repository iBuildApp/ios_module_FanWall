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


#import "mFWRepliesCell.h"
#import "mFWConnection.h"

#define kLeftMargin 10.f
#define kTopMargin  10.f
#define kLogoWidth  36.f
#define kLogoHeight 36.f
#define kTopCommentsBarHeight 29.f

#define kImageViewBorder 3.f

@interface mFWRepliesCell()

  @property(nonatomic, strong) mFWConnection  *FWConnection;

@end

@implementation mFWRepliesCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self)
  {
    self.backgroundColor = [UIColor clearColor];
    _messageLabel = nil;
    _dateDiffLabel = nil;
    _attachedImageView = nil;
    _phImageView = nil;
    _commentsLabel = nil;
    _separatorLine = nil;
    _FWConnection = [mFWConnection sharedInstance];
  }
  return self;
}

- (void)dealloc
{
  if (_messageLabel)
      [_messageLabel release];
  
  _messageLabel = nil;
  
  
  if (_dateDiffLabel)
    [_dateDiffLabel release];
  
  _dateDiffLabel = nil;
  
  
  if (_phImageView)
      [_phImageView release];
  
  _phImageView = nil;
  
  
  if (_attachedImageView)
    [_attachedImageView release];
  
  _attachedImageView = nil;
  
  
  if (_commentsLabel)
    [_commentsLabel release];
  
  _commentsLabel = nil;
  
  if (_separatorLine)
    [_separatorLine release];
  
  _separatorLine = nil;
  
  
  [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  self.imageView.frame = CGRectMake(kLeftMargin, kTopMargin, kLogoWidth, kLogoHeight);
  self.imageView.layer.cornerRadius = 4.0f;
  self.imageView.layer.masksToBounds = YES;
  self.imageView.userInteractionEnabled = YES;
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  self.imageView.layer.masksToBounds = YES;
  self.imageView.clipsToBounds = YES;
  
  
  self.textLabel.textAlignment = NSTextAlignmentLeft;
  self.textLabel.font = [UIFont boldSystemFontOfSize:13.0f];
  self.textLabel.frame = CGRectMake(kLeftMargin*2 + kLogoWidth, kTopMargin, self.contentView.bounds.size.width - (kLeftMargin*3 + kLogoWidth), 15);
  self.textLabel.userInteractionEnabled = YES;

  self.attachedImageView.backgroundColor = [UIColor whiteColor];
  self.attachedImageView.clipsToBounds = YES;
  
  
  self.phImageView.contentMode = UIViewContentModeScaleAspectFill;
}


- (UIView *)attachedImageView
{
  if ( !_attachedImageView )
  {
    _attachedImageView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_attachedImageView];
    
    _attachedImageView.userInteractionEnabled = YES;
  }
  return _attachedImageView;
}


- (UIImageView *)phImageView
{
  if ( !_phImageView )
  {
    _phImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.attachedImageView addSubview:_phImageView];
  }
  return _phImageView;
}


- (UILabel *)dateDiffLabel
{
  if ( !_dateDiffLabel)
  {
    _dateDiffLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_dateDiffLabel];
  }
  return _dateDiffLabel;
}

- (UILabel *)messageLabel
{
  if ( !_messageLabel)
  {
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_messageLabel];
  }
  return _messageLabel;
}


- (UILabel *)commentsLabel
{
  if ( !_commentsLabel)
  {
    _commentsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_commentsLabel];
  }
  return _commentsLabel;
}

- (UIView *)separatorLine
{
  if ( !_separatorLine)
  {
    _separatorLine = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_separatorLine];
  }
return _separatorLine;
}

@end
