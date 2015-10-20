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

#import "mFWSocialButton.h"
#import "NSString+size.h"

@interface mFWSocialButton()

@property (nonatomic, retain) UILabel *countLabel;
@property (nonatomic, retain) UIView *socialView;
@property (nonatomic, retain, readwrite) UIImageView *socialImageView;

@end

@implementation mFWSocialButton

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if(self){
    self.socialView = [[UIView alloc] initWithFrame:CGRectZero];
    self.countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.socialImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    _countLabel.backgroundColor = [UIColor clearColor];
    _countLabel.font = [UIFont systemFontOfSize:(kSocialActionsCountFontSize)];
    _socialView.backgroundColor = [UIColor clearColor];
    
    _socialImageView.clipsToBounds = YES;
    _countLabel.clipsToBounds = YES;
    
    [self addSubview:_socialView];
    [_socialView addSubview:_socialImageView];
    [_socialView addSubview:_countLabel];
    
    self.userInteractionEnabled = YES;
  }
  
  return self;
}

-(void)setSocialImage:(UIImage *)socialImage
{
  if(socialImage != nil){
    [socialImage retain];
    [_socialImage release];
    _socialImage = socialImage;
    
    CGSize socialImageViewSize = _socialImageView.bounds.size;
    CGSize newImageSize = socialImage.size;
    
    if(!CGSizeEqualToSize(socialImageViewSize, newImageSize)){
      CGRect newsocialImageViewBounds = _socialImageView.frame;
      newsocialImageViewBounds.size = newImageSize;
      
      _socialImageView.bounds = newsocialImageViewBounds;
      
      [self updateCountLabelPosition];
      [self centerImageAndLabel];
    }
    
    _socialImageView.image = _socialImage;
  }
}



-(void)setSocialActionsCount:(NSUInteger)socialActionsCount
{
  _socialActionsCount = socialActionsCount;

  NSString *actionsCountString = [NSString stringWithFormat:@"%lu" ,(unsigned long)socialActionsCount];
  
  CGSize labelSize = _countLabel.bounds.size;
  CGSize stringSize = [actionsCountString sizeWithFont:_countLabel.font];
  
  if(!CGSizeEqualToSize(labelSize, stringSize)){
    CGRect newCountLabelBounds = _countLabel.frame;
    newCountLabelBounds.size = stringSize;
    
    _countLabel.bounds = newCountLabelBounds;
    
    [self updateCountLabelPosition];
    [self centerImageAndLabel];
  }
  
  _countLabel.text = actionsCountString;
}

-(void) centerImageAndLabel
{
  CGFloat socialViewHeight =
  _socialImage.size.height > _countLabel.frame.size.height ?
  _socialImage.size.height : _countLabel.frame.size.height;
  
  CGFloat socialViewWidth = _socialImage.size.width
  + (_socialImage.size.width > 0 ? kSpaceBetweenSocialImageAndActionsCount : 0.0f)
  + _countLabel.frame.size.width;
  
  _socialView.frame = (CGRect){0.0f, 0.0f, socialViewWidth, socialViewHeight};
  
  _socialView.center = (CGPoint){self.bounds.size.width / 2, self.bounds.size.height / 2};
  
  CGPoint centerOfsocialImageViewInSelf = [_socialImageView convertPoint:_socialImageView.bounds.origin toView:self];
  CGFloat offsetX = _socialView.frame.origin.x - centerOfsocialImageViewInSelf.x;
  CGFloat offsetY = _socialView.frame.origin.y - centerOfsocialImageViewInSelf.y;
  
  CGRect newsocialImageViewFrame = _socialImageView.frame;
  newsocialImageViewFrame.origin.x += offsetX;
  newsocialImageViewFrame.origin.y += offsetY;
  _socialImageView.frame = newsocialImageViewFrame;
  
  CGRect newCountLabelFrame = _countLabel.frame;
  newCountLabelFrame.origin.x += offsetX;
  newCountLabelFrame.origin.y += offsetY;
  _countLabel.frame = newCountLabelFrame;
}

-(void) updateCountLabelPosition
{
  CGRect newCountLabelFrame = _countLabel.frame;
  newCountLabelFrame.origin.x = _socialImageView.frame.origin.x + _socialImageView.frame.size.width + kSpaceBetweenSocialImageAndActionsCount;
  
  _countLabel.frame = newCountLabelFrame;
}

- (void) dealloc
{
  self.socialImage = nil;
  self.countLabel = nil;
  self.socialImageView = nil;
  self.socialView = nil;
  
  [super dealloc];
}

@end
