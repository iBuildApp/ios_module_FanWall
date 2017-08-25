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


#import "mFWPostCell.h"

@interface mFWPostCell()

@property (nonatomic, readwrite, strong) NSString *attachedImageThumbnailURL;

@end;

@implementation mFWPostCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self)
  {
    self.backgroundColor = [UIColor clearColor];
    self.userNameLabel = self.textLabel;
    self.postDateLabel = self.detailTextLabel;
    _attachedImageThumbnailURL = nil;
    _attachedThumbnailImageView = nil;
    self.avatarImageView = self.imageView;
  }
  return self;
}


- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self setupImageViewInCell];
  [self setupLabelsInCell];
}

- (void) setupImageViewInCell
{
  self.imageView.frame = CGRectMake(kMarginFromScreenEdges + kPostContentsPaddingLeft, kAvatarPaddingTop, kAvatarImageViewWidthAndHeight, kAvatarImageViewWidthAndHeight);
  self.imageView.layer.cornerRadius = kAvatarImageViewBorderRadius;
  self.imageView.layer.masksToBounds = YES;
  self.imageView.userInteractionEnabled = YES;
  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void) setupLabelsInCell
{
  float textLabelHeight = kUserNameLabelTextSize + 1;
  float textLabelsOriginX = self.imageView.frame.origin.x + kAvatarImageViewWidthAndHeight + kSpaceBetweenImageAndTextLabels;
  
  CGSize labelSize = [self.textLabel.text sizeForFont:self.textLabel.font
                                            limitSize:CGSizeMake(kMaxAllowedTextLabelWidth, textLabelHeight)
                                      nslineBreakMode:self.textLabel.lineBreakMode];
  self.textLabel.font = [UIFont systemFontOfSize:kUserNameLabelTextSize];
  self.textLabel.frame = CGRectMake(textLabelsOriginX, kPostContentsPaddingTop, labelSize.width, textLabelHeight);
  
  float detailTextLabelHeight = kHoursAgoLabelTextSize + 1;
  
  self.detailTextLabel.frame = CGRectMake(textLabelsOriginX, 28.0f, kMaxAllowedTextLabelWidth, detailTextLabelHeight);
  self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
  self.detailTextLabel.font = [UIFont systemFontOfSize:kHoursAgoLabelTextSize];
  self.detailTextLabel.textColor = kHoursAgoLabelTextColor;
}

-(NSString *) attachedImageThumbnailURL{
    if(self.attachedThumbnailImageViewContainer.hidden){
        return nil;
    }
    return _attachedImageThumbnailURL;
}

-(void)setAttachedImageThumbnailForURL:(NSString *)URL withPlaceholderImage:(UIImage *)placeholderImage
{
    self.attachedImageThumbnailURL = URL;
    
    SDWebImageSuccessBlock fadeInBlock = ^(UIImage *image, BOOL cached)
    {
        // if(!cached){
        self.attachedThumbnailImageViewContainer.alpha = 0.0f;
        [UIView animateWithDuration:kFadeInDuration animations:^{
            self.attachedThumbnailImageViewContainer.alpha = 1.0f;
        }];
        // }
    };
    
    [self.attachedThumbnailImageView setImageWithURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                placeholderImage:self.attachedThumbnailImageView.image ? self.attachedThumbnailImageView.image : placeholderImage
                         success:fadeInBlock
                         failure:nil];
    
}

-(void)setAvatarImageForURL:(NSString *)URL withPlaceholderImage:(UIImage *)placeholderImage;
{
    SDWebImageSuccessBlock fadeInBlock = ^(UIImage *image, BOOL cached)
    {
        if(!cached){
            self.avatarImageView.alpha = 0.0f;
            [UIView animateWithDuration:kFadeInDuration animations:^{
                self.avatarImageView.alpha = 1.0f;
            }];
        }
    };
    
    [self.avatarImageView setImageWithURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                   placeholderImage:placeholderImage
                            success:nil
                            failure:nil];
    
}

@end
