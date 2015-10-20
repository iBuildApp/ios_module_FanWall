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

#import "mFWExpandingTextViewInternal.h"

#define kTopContentInset 4
#define kBottonContentInset 12

@implementation mFWExpandingTextViewInternal

-(void)setContentOffset:(CGPoint)s
{
    /* Check if user scrolled */
	if(self.tracking || self.decelerating)
    {
		self.contentInset = UIEdgeInsetsMake(kTopContentInset, 0, 0, 0);
	}
    else
    {
		float bottomContentOffset = (self.contentSize.height - self.frame.size.height + self.contentInset.bottom);
		if(s.y < bottomContentOffset && self.scrollEnabled)
        {
			self.contentInset = UIEdgeInsetsMake(kTopContentInset, 0, kBottonContentInset, 0);
		}
	}
	[super setContentOffset:s];
}

-(void)setContentInset:(UIEdgeInsets)s
{
	UIEdgeInsets edgeInsets = s;
	edgeInsets.top = kTopContentInset;
	if(s.bottom > 12)
    {
        edgeInsets.bottom = 4;
    }
	[super setContentInset:edgeInsets];
}

@end
