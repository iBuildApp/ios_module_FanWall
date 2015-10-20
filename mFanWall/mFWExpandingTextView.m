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

#import "mFWExpandingTextView.h"
#import "mFWInputToolbar.h"

#define kTextInsetX 4
#define kTextInsetBottom 0

#define kInputToolbarExpandingTextViewMaximumHeight 60.0

@interface mFWExpandingTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;

@property (nonatomic, assign) CGFloat minimumHeight;
@property (nonatomic, assign) CGFloat maximumHeight;

@property (nonatomic, assign) UIScrollView *imageGalleryScrollView;

@property (nonatomic, assign) BOOL forceSizeUpdate;

-(CGFloat) measureHeightOfUITextView:(UITextView *)textView;

@end

@implementation mFWExpandingTextView

- (id)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame]))
  {
    self.forceSizeUpdate     = NO;
    self.autoresizingMask    = UIViewAutoresizingFlexibleWidth;
		CGRect backgroundFrame   = frame;
    backgroundFrame.origin.y = 0.0f;
		backgroundFrame.origin.x = 0.0f;
    
    CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, 0.0f);
    
    /* Internal Text View component */
		self.internalTextView = [[UITextView alloc] initWithFrame:textViewFrame];
		self.internalTextView.delegate        = self;
		self.internalTextView.font            = [UIFont systemFontOfSize:15.0];
		self.internalTextView.contentInset    = UIEdgeInsetsMake(-4.0f, 1.0, -4.0f, 0.0f);
		self.internalTextView.scrollEnabled   = NO;
    self.internalTextView.opaque          = NO;
    self.internalTextView.backgroundColor = [UIColor clearColor];
    self.internalTextView.showsHorizontalScrollIndicator = NO;
    [self.internalTextView sizeToFit];
    self.internalTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.internalTextView.backgroundColor = [UIColor whiteColor];
    
    /* set placeholder */
    self.placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(8.0f, 3.0f, self.bounds.size.width - 16.0f, self.bounds.size.height)];
    self.placeholderLabel.text = self.placeholder;
    self.placeholderLabel.font = self.internalTextView.font;
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    self.placeholderLabel.textColor = [UIColor grayColor];
    [self.internalTextView addSubview:self.placeholderLabel];
    
    [self addSubview:self.internalTextView];
    
    /* Calculate the text view height */
		UIView *internal = (UIView*)[[self.internalTextView subviews] objectAtIndex:0];
		self.minimumHeight = internal.frame.size.height;
      self.animateHeightChange = NO;//YES;
		self.internalTextView.text = @"";
    
    self.maximumHeight = kInputToolbarExpandingTextViewMaximumHeight; // 3 lines of text
    
    [self sizeToFit];
  }
  return self;
}

-(void)sizeToFit
{
  CGRect r = self.frame;
  if ([self.text length] > 0)
  {
    /* No need to resize is text is not empty */
    return;
  }
  r.size.height = self.minimumHeight + kTextInsetBottom;
  self.frame = r;
}

-(void)setFrame:(CGRect)aframe
{
  CGRect backgroundFrame   = aframe;
  backgroundFrame.origin.y = 0;
  backgroundFrame.origin.x = 0;
  CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, 0);
	self.internalTextView.frame   = textViewFrame;
  backgroundFrame.size.height  -= 8;
  self.textViewBackgroundImage.frame = backgroundFrame;
  self.forceSizeUpdate = YES;
	[super setFrame:aframe];
}

-(void)clearText
{
  self.text = @"";
  [self textViewDidChange:self.internalTextView];
}


- (void)textViewDidChange:(UITextView *)textView
{
	NSInteger newHeight;
  if(floor(NSFoundationVersionNumber)>NSFoundationVersionNumber_iOS_6_1) {
    newHeight = [self measureHeightOfUITextView:self.internalTextView];
  }else {
    newHeight = self.internalTextView.contentSize.height;
  }
  
	if(newHeight < self.minimumHeight || !self.internalTextView.hasText)
  {
    newHeight = self.minimumHeight;
  }
  
	if (self.internalTextView.frame.size.height != newHeight || self.forceSizeUpdate)
	{
    self.forceSizeUpdate = NO;
    if (newHeight > self.maximumHeight && self.internalTextView.frame.size.height <= self.maximumHeight)
    {
      newHeight = self.maximumHeight;
    }
		if (newHeight <= self.maximumHeight)
		{
			if(self.animateHeightChange)
      {
				[UIView beginAnimations:@"" context:nil];
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(growDidStop)];
				[UIView setAnimationBeginsFromCurrentState:YES];
			}
      
			if ([self.delegate respondsToSelector:@selector(expandingTextView:willChangeHeight:)])
      {
				[self.delegate expandingTextView:self willChangeHeight:(newHeight+ kTextInsetBottom)];
			}
      
			/* Resize the frame */
			CGRect r = self.frame;
			r.size.height = newHeight + kTextInsetBottom;
			self.frame = r;
			r.origin.y = 0;
			r.origin.x = 0;
      self.internalTextView.frame = CGRectInset(r, kTextInsetX, 0);
      r.size.height -= 8;
      self.textViewBackgroundImage.frame = r;
      
			if(self.animateHeightChange)
      {
				[UIView commitAnimations];
			}
      else if ([self.delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)])
      {
        [self.delegate expandingTextView:self didChangeHeight:(newHeight+ kTextInsetBottom)];
      }
		}
    
		if (newHeight >= self.maximumHeight)
		{
      /* Enable vertical scrolling */
			if(!self.internalTextView.scrollEnabled)
      {
				self.internalTextView.scrollEnabled = YES;
				[self.internalTextView flashScrollIndicators];
			}
		}
    else
    {
      /* Disable vertical scrolling */
			self.internalTextView.scrollEnabled = NO;
		}
	}
  
	if ([self.delegate respondsToSelector:@selector(expandingTextViewDidChange:)])
  {
		[self.delegate expandingTextViewDidChange:self];
	}
}

-(void)growDidStop
{
	if ([self.delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)])
  {
		[self.delegate expandingTextView:self didChangeHeight:self.frame.size.height];
	}
}

-(BOOL)resignFirstResponder
{
	[super resignFirstResponder];
	return [self.internalTextView resignFirstResponder];
}

#pragma mark UITextView properties


-(NSTextAlignment)textAlignment
{
	return (NSTextAlignment)self.internalTextView.textAlignment;
}

-(void)setSelectedRange:(NSRange)range
{
	self.internalTextView.selectedRange = range;
}

-(NSRange)selectedRange
{
	return self.internalTextView.selectedRange;
}

-(void)setEditable:(BOOL)beditable
{
	self.internalTextView.editable = beditable;
}

-(BOOL)isEditable
{
	return self.internalTextView.editable;
}

-(void)setReturnKeyType:(UIReturnKeyType)keyType
{
	self.internalTextView.returnKeyType = keyType;
}

-(UIReturnKeyType)returnKeyType
{
	return self.internalTextView.returnKeyType;
}

-(void)setDataDetectorTypes:(UIDataDetectorTypes)datadetector
{
	self.internalTextView.dataDetectorTypes = datadetector;
}

-(UIDataDetectorTypes)dataDetectorTypes
{
	return self.internalTextView.dataDetectorTypes;
}

- (BOOL)hasText
{
	return [self.internalTextView hasText];
}

- (void)scrollRangeToVisible:(NSRange)range
{
	[self.internalTextView scrollRangeToVisible:range];
}

#pragma mark -
#pragma mark UIExpandingTextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(expandingTextViewShouldBeginEditing:)])
  {
		return [self.delegate expandingTextViewShouldBeginEditing:self];
	}
  else
  {
		return YES;
	}
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(expandingTextViewShouldEndEditing:)])
  {
		return [self.delegate expandingTextViewShouldEndEditing:self];
	}
  else
  {
		return YES;
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
  self.placeholderLabel.alpha = 0;
  
	if ([self.delegate respondsToSelector:@selector(expandingTextViewDidBeginEditing:)])
  {
		[self.delegate expandingTextViewDidBeginEditing:self];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
  self.placeholderLabel.alpha = 1;
  
  if ([self.delegate respondsToSelector:@selector(expandingTextViewDidEndEditing:)])
  {
    [self.delegate expandingTextViewDidEndEditing:self];
  }
}


- (BOOL)textViewShouldReturn:(UITextView *)textView
{
  [self performSelector:@selector(textViewDidChange:) withObject:self.internalTextView];
  return NO;
}

#define MAX_LENGTH 150 // Max message length

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)atext
{
	if(![textView hasText] && [atext isEqualToString:@""])
  {
    return NO;
	}
  
  NSUInteger newLength = (textView.text.length - range.length) + atext.length;
  if(newLength > MAX_LENGTH) {
    NSUInteger emptySpace = MAX_LENGTH - (textView.text.length - range.length);
    textView.text = [[[textView.text substringToIndex:range.location] stringByAppendingString:[atext substringToIndex:emptySpace]] stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
    return NO;
  }
  
	if ([atext isEqualToString:@"\n"])
  {
		if ([self.delegate respondsToSelector:@selector(expandingTextViewShouldReturn:)])
    {
			if (![self.delegate performSelector:@selector(expandingTextViewShouldReturn:) withObject:self])
      {
				return YES;
			}
      else
      {
				[textView resignFirstResponder];
				return NO;
			}
		}
	}
	return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(expandingTextViewDidChangeSelection:)])
  {
		[self.delegate expandingTextViewDidChangeSelection:self];
	}
}

@end
