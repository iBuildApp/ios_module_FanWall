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

#import "mFWInputToolbar.h"
#import "mFWImageProvider.h"

#import "NSString+size.h"

@interface mFWInputToolbar() {
    id<mFWInputToolbarDelegate> __weak _inputToolbarDelegate;
    
    CGFloat textViewOriginX;
    CGFloat textViewShortenedOriginX;
}

@property (nonatomic, strong) UIImageView *pickedImageInTextView;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *borderView;

@property (nonatomic, strong) UIView *previewPaneSpacerView;
@property (nonatomic, strong) UIScrollView *previewPaneScrollView;

@property (nonatomic, strong) UIView *previewPane;

@property (nonatomic, strong) mFWImageProvider *imageProvider;

@end


@implementation mFWInputToolbar

NSString *const kFWMessagePostNotificationName = @"FWMessagePost";
NSString *const kFWMessagePostTextKey = @"message";
NSString *const kFWMessagePostImagesKey = @"images";

-(id)initWithFrame:(CGRect)frame andManagingController:(UIViewController *)managingController
{
    if(self = [super initWithFrame:frame]){
      
        _pickFromGalleryImageView = nil;
        _takeAPhotoImageView = nil;
        
        _previewPaneSpacerView = nil;
        _previewPaneScrollView = nil;
        
        _previewPane = nil;
        _borderView = nil;
        _backgroundView = nil;
        
        _pickedImages = [[NSMutableArray alloc] init];
        
        _multiImageMode = NO;
        
        self.managingController = managingController;
        
        _notificationName = kFWMessagePostNotificationName;
        
        self.imageProvider = [[mFWImageProvider alloc] initWithImageConsumer:self andDialogPresenter:self.managingController];
        
        [self setupToolbar];
    }
    return self;
}

-(void)setupToolbar{
    
    CGRect frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height);
    self.backgroundView = [[UIView alloc] initWithFrame:frame];
    [self.backgroundView setBackgroundColor:kInputToolBarColor];
    [self addSubview:self.backgroundView];
    
    self.barStyle = UIBarStyleBlackOpaque;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    
    if(CGRectEqualToRect(self.frame, kFramePendingInitialization)){
        CGRect inputToolbarFrame = CGRectMake(0.0f, self.frame.size.height - kInputToolbarInitialHeight, self.frame.size.width,  kInputToolbarInitialHeight);
        
        self.frame = inputToolbarFrame;
    }
    
    UIView *topBorder = [self makeHorizontalBorder];
    topBorder.backgroundColor = kBorderColor;
    [self addSubview:topBorder];
    
    self.backgroundColor = kInputToolBarColor;
    
    CGRect borderViewFrame = CGRectZero;
    CGFloat textViewMargin = kPrimaryIconsWidthAndHeight;
    
    borderViewFrame.origin.x = textViewMargin;
    borderViewFrame.origin.y = (kInputToolbarInitialHeight - kInputToolbarExpandingTextViewInitialHeight) / 2;
    borderViewFrame.size.height = kInputToolbarExpandingTextViewInitialHeight;
    borderViewFrame.size.width = self.frame.size.width - 2 * textViewMargin;
    
    textViewOriginX = borderViewFrame.origin.x;
    
    self.borderView = [[UIView alloc] initWithFrame:borderViewFrame];
    self.borderView.backgroundColor = [UIColor clearColor];
    self.borderView.layer.borderColor = [UIColor colorWithWhite:0.770 alpha:1.0f].CGColor;
    self.borderView.layer.borderWidth = 1.0f;
    self.borderView.layer.cornerRadius = 3.0f;
    self.borderView.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.borderView.alpha = 1.0f;
    self.borderView.clipsToBounds = YES;
    
    self.textView = [[mFWExpandingTextView alloc] initWithFrame:
                     CGRectMake(0.0f, 0.0f,borderViewFrame.size.width,borderViewFrame.size.height)];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.owner = self;

    self.textView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    self.textView.delegate = self;
    
    [self.borderView addSubview:self.textView];
    [self addSubview:self.borderView];
    
    UIImage *pickerImage = [UIImage imageNamed:resourceFromBundle(@"mFW_hamburger")];
    UIImage *senderImage = [UIImage imageNamed:resourceFromBundle(@"mFW_send")];
    
    CGRect imagePickerFrame = CGRectMake(0.0f, 0.0f, kPrimaryIconsWidthAndHeight, kInputToolbarInitialHeight);
    self.imagePickerImageView = [[UIImageView alloc] initWithFrame:imagePickerFrame];
    self.imagePickerImageView.image = pickerImage;
    self.imagePickerImageView.userInteractionEnabled = YES;

    self.imagePickerImageView.contentMode = UIViewContentModeCenter;
    
    [self addSubview:self.imagePickerImageView];
    
    
    CGRect senderFrame = CGRectMake(textViewMargin + borderViewFrame.size.width,
                                    0.0f,
                                    kPrimaryIconsWidthAndHeight,
                                    kPrimaryIconsWidthAndHeight);
    
    self.senderImageView = [[UIImageView alloc] initWithFrame:senderFrame];
    self.senderImageView.image = senderImage;
    self.senderImageView.userInteractionEnabled = YES;
    
    self.senderImageView.contentMode = UIViewContentModeCenter;
    
    [self addSubview:self.senderImageView];
    
    UITapGestureRecognizer *imagePickerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hamburgerControlPressed)];
    
    UITapGestureRecognizer *senderTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(senderControlPressed)];
    
    [self.imagePickerImageView addGestureRecognizer:imagePickerTapGestureRecognizer];
    [self.senderImageView addGestureRecognizer:senderTapGestureRecognizer];

    
    [self adjustIconsToVerticalCenter];
    
    self.auxiliaryToolbar = [self constructAuxiliaryToolbar];
    [self addSubview:self.auxiliaryToolbar];
}


-(void)senderControlPressed
{
    NSString *messageText = [self.textView.text copy];
    if (messageText.length > 0) {
        [self.textView resignFirstResponder];
    }
    if(messageText.length > 0 || self.pickedImages.count > 0){
        [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName object:nil userInfo:[NSDictionary dictionaryWithObjects:@[messageText, self.pickedImages] forKeys:@[kFWMessagePostTextKey, kFWMessagePostImagesKey]]];
    }
}

-(void)clear
{
    [self.textView clearText];
    
    if(self.pickedImages.count > 0){
        [self.pickedImages removeAllObjects];
    }
    if(!self.previewPane.hidden){
        [self hidePreviewPane];
        [self adjustIconsToVerticalCenter];
    }
}

- (void)drawRect:(CGRect)rect
{
    if([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        [[UIColor colorWithWhite:1.0f alpha:1.0f] set];
    } else {
        [[UIColor colorWithWhite:0.0f alpha:0.4f] set];
    }
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
}

- (void) adjustViewWidth:(UIView *) view forNewOriginX:(CGFloat)newOriginX
{
    CGRect newViewFrame = view.frame;
    CGFloat offset = newViewFrame.origin.x - newOriginX;
    newViewFrame.origin.x = newOriginX;
    newViewFrame.size.width += offset;
    view.frame = newViewFrame;
}

- (void) performTextViewWidthChanging:(CGFloat)newOriginX
{
    [self adjustViewWidth:self.borderView forNewOriginX:newOriginX];
    
    self.previewPane.frame = CGRectMake(0,
                                        self.previewPane.frame.origin.y,
                                        self.borderView.frame.size.width,
                                        self.previewPane.frame.size.height);
    
    self.previewPaneSpacerView.frame = CGRectMake(kPreviewImageLeftPadding,
                                                  self.previewPaneSpacerView.frame.origin.y,
                                                  self.borderView.frame.size.width - 2 * kPreviewImageLeftPadding,
                                                  self.previewPaneSpacerView.frame.size.height);
    
    self.previewPaneScrollView.frame = CGRectMake(0.0f,
                                                  self.previewPaneScrollView.frame.origin.y,
                                                  self.borderView.frame.size.width,
                                                  self.previewPaneScrollView.frame.size.height);
    
    [self.textView textViewDidChange:self.textView.internalTextView];
    self.textView.internalTextView.pagingEnabled = NO;
}

- (void) shortenTextView
{
    [self performTextViewWidthChanging:textViewShortenedOriginX];
}

- (void) restoreTextViewWidth
{
    [self performTextViewWidthChanging:textViewOriginX];
}

#pragma mark -
#pragma mark UIExpandingTextView delegate

-(void)expandingTextView:(mFWExpandingTextView *)expandingTextView willChangeHeight:(float)height
{
    /* Adjust the height of the toolbar when the input component expands */
    CGFloat diff = (self.textView.frame.size.height - height);
    CGRect r = self.frame;
    r.origin.y += diff;
    r.size.height -= diff;
    self.frame = r;
    
    self.backgroundView.frame = self.bounds;
    
    CGRect newBorderFrame = self.borderView.frame;
    newBorderFrame.size.height -= diff;
    self.borderView.frame = newBorderFrame;
    
    [self adjustIconsToVerticalCenter];

    _auxiliaryToolbar.frame = CGRectOffset(_auxiliaryToolbar.frame, 0.0f, -diff);
    
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        [self.inputToolbarDelegate expandingTextView:expandingTextView willChangeHeight:height];
    }
}

-(void)expandingTextViewDidChange:(mFWExpandingTextView *)expandingTextView
{
    if ([self.inputToolbarDelegate respondsToSelector:@selector(expandingTextViewDidChange:)])
        [self.inputToolbarDelegate expandingTextViewDidChange:expandingTextView];
}

- (BOOL)expandingTextViewShouldReturn:(mFWExpandingTextView *)expandingTextView
{
    return NO;
}

- (BOOL)expandingTextViewShouldBeginEditing:(mFWExpandingTextView *)expandingTextView
{
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        return [self.inputToolbarDelegate expandingTextViewShouldBeginEditing:expandingTextView];
    }
    return YES;
}

- (BOOL)expandingTextViewShouldEndEditing:(mFWExpandingTextView *)expandingTextView
{
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        return [self.inputToolbarDelegate expandingTextViewShouldEndEditing:expandingTextView];
    }
    return YES;
}

- (void)expandingTextViewDidBeginEditing:(mFWExpandingTextView *)expandingTextView
{
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        [self.inputToolbarDelegate expandingTextViewDidBeginEditing:expandingTextView];
    }
}

- (void)expandingTextViewDidEndEditing:(mFWExpandingTextView *)expandingTextView
{
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        [self.inputToolbarDelegate expandingTextViewDidEndEditing:expandingTextView];
    }
}

- (BOOL)expandingTextView:(mFWExpandingTextView *)expandingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        return [self.inputToolbarDelegate expandingTextView:expandingTextView shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

- (void)expandingTextView:(mFWExpandingTextView *)expandingTextView didChangeHeight:(float)height
{
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        [self.inputToolbarDelegate expandingTextView:expandingTextView didChangeHeight:height];
    }
}

- (void)expandingTextViewDidChangeSelection:(mFWExpandingTextView *)expandingTextView
{
    if ([self.inputToolbarDelegate respondsToSelector:_cmd]) {
        [self.inputToolbarDelegate expandingTextViewDidChangeSelection:expandingTextView];
    }
}

#pragma mark mFWInputToolbar controls' tap hadlers
- (void) hamburgerControlPressed
{
  CGFloat heightDiff = _auxiliaryToolbar.hidden ? kAuxiliaryToolbarHeight : - kAuxiliaryToolbarHeight;
  
  NSNotification *auxiliaryToolbarToggledNotification = [NSNotification notificationWithName:kAuxiliaryToolbarToggledNotificationName object:nil userInfo:@{kAuxiliaryToolbarToggledHeightDiffNotificationKey : [NSNumber numberWithFloat:heightDiff]}];
  
  [[NSNotificationCenter defaultCenter] postNotification:auxiliaryToolbarToggledNotification];
  
    [UIView animateWithDuration:kAuxiliaryToolbarTogglingAnimationDuration animations:^{
        [self toggleAuxiliaryToolbarVisibility];
    }];
}

- (void) takeAPhoto:(UITapGestureRecognizer *)recognizer
{
    [self.imageProvider provideAnImageWithCamera];
}

- (void) pickFromGallery:(UITapGestureRecognizer *)recognizer
{
    [self.imageProvider provideAnImageFromGallery];
}

- (void) toggleGeolocation:(UITapGestureRecognizer *)recognizer
{
  if(self.inputToolbarDelegate){
   [self.inputToolbarDelegate mFWInputToolbarDidToggleGeolocation:self];
  }
}

#pragma mark mFWImageConsumer delegate methods
- (void) imagePickedCallback:(UIImage *)image
{
    NSLog(@"Got image from provider");
    
    UIImage *ourImage = image;
    
    if(self.multiImageMode){
        [self.pickedImages addObject:ourImage];
    } else {
        if(self.pickedImages.count > 1){
            [self.pickedImages removeAllObjects];
        }
        [self.pickedImages setObject:ourImage atIndexedSubscript:0];
    }
    
    if(self.previewPane == nil){
        
        self.previewPane = [self constructPreviewPane];
        [self.borderView addSubview:self.previewPane];
        [self showPreviewPane];
        [self adjustIconsToVerticalCenter];
    }
    [self refreshPreviewPane];
}

#pragma mark mFWInputToolbar view management methods
- (void) adjustIconsToVerticalCenter
{
    [self adjustViewToHorizontalCenterOfSuperView:self.imagePickerImageView];
    [self adjustViewToHorizontalCenterOfSuperView:self.senderImageView];
}

- (void) adjustViewToHorizontalCenterOfSuperView:(UIView *) viewToResize
{
    CGPoint oldCenter = viewToResize.center;
    
    CGFloat height = _auxiliaryToolbar.hidden ?
    self.frame.size.height : self.frame.size.height - _auxiliaryToolbar.frame.size.height;
    
    CGPoint newCenter = CGPointMake(oldCenter.x, height / 2);
    
    viewToResize.center = newCenter;
}


- (void) toggleAuxiliaryToolbarVisibility
{
    if(_auxiliaryToolbar.hidden){
        [self showAuxiliaryToolbar];
    } else {
        [self hideAuxiliaryToolbar];
    }
}

-(void) showAuxiliaryToolbar
{
    __block CGRect inputToolbarFrame = self.frame;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        _auxiliaryToolbar.hidden = NO;
        inputToolbarFrame.origin.y -= kAuxiliaryToolbarHeight;
        inputToolbarFrame.size.height += kAuxiliaryToolbarHeight;
        self.frame = inputToolbarFrame;
        
    }];
}

-(void) hideAuxiliaryToolbar
{
    __block CGRect inputToolbarFrame = self.frame;
    __block CGRect auxiliaryToolbarFrame = _auxiliaryToolbar.frame;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        inputToolbarFrame.origin.y += kAuxiliaryToolbarHeight;
        inputToolbarFrame.size.height -= kAuxiliaryToolbarHeight;
        
        auxiliaryToolbarFrame.size.height = 0; //*
        
        self.frame = inputToolbarFrame;
        _auxiliaryToolbar.frame = auxiliaryToolbarFrame;
        
    } completion:^(BOOL finished){
        _auxiliaryToolbar.hidden = YES; //*
        auxiliaryToolbarFrame.size.height = kAuxiliaryToolbarHeight; //* to make it move under transparent keyboard nicely
        auxiliaryToolbarFrame.origin.y = self.frame.size.height;
        _auxiliaryToolbar.frame = auxiliaryToolbarFrame;
    }];
}

- (void) populatePreviewPaneWithImages
{
    if(self.previewPaneScrollView != nil)
    {
        CGFloat previewImageOriginX = kPreviewImageLeftPadding;
        
        NSUInteger imagesCount = self.pickedImages.count;
        for(NSUInteger i = 0; i < imagesCount; i++)
        {
            UIImage *image = [self.pickedImages objectAtIndex:i];
            
            if(previewImageOriginX >= self.previewPaneScrollView.contentSize.width)
            {
                CGSize newContentSize = self.previewPaneScrollView.contentSize;
                newContentSize.width = previewImageOriginX + kPreviewImageWidthAndHeight + kSpaceBetweenImages;
                self.previewPaneScrollView.contentSize = newContentSize;
            }
            
            CGRect previewImageFrame = CGRectMake(previewImageOriginX, 0.0f, kPreviewImageWidthAndHeight, kPreviewImageWidthAndHeight);
            UIImageView *previewImageView = [[UIImageView alloc] initWithFrame:previewImageFrame];
            previewImageView.image = image;
            previewImageView.contentMode = UIViewContentModeScaleAspectFill;
            previewImageView.clipsToBounds = YES;
            
            UIImageView *removePreviewCross = [[UIImageView alloc] initWithImage:[UIImage imageNamed:resourceFromBundle(@"mFW_remove_preview")]];
            
            removePreviewCross.center = CGPointMake(previewImageOriginX + kPreviewImageWidthAndHeight - kRemovePreviewCrossShift, kRemovePreviewCrossShift + 2.0f);
            
            
            removePreviewCross.tag = kFirstPreviewToRemoveTag + i;
            removePreviewCross.userInteractionEnabled = YES;
            
            previewImageView.tag = removePreviewCross.tag;
            
            UITapGestureRecognizer *removeRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removePreviewImage:)];
            
            [removePreviewCross addGestureRecognizer:removeRecognizer];
            
            [self.previewPaneScrollView addSubview:previewImageView];
            
            [self.previewPaneScrollView insertSubview:removePreviewCross aboveSubview:previewImageView];
            
            
            previewImageOriginX += kPreviewImageWidthAndHeight + kSpaceBetweenImages;
        }
    }
}

- (void) refreshPreviewPane
{
    for(UIView *view in self.previewPaneScrollView.subviews){
        if(view.tag != 0){ // Do not remove scroll indicators
            // Got EXC_BAD_ACCESS after removing them
            [view removeFromSuperview];
        }
    }
    self.previewPaneScrollView.contentSize = CGSizeMake(0, self.previewPaneScrollView.contentSize.height);
    if(self.pickedImages.count > 0){
        if(self.previewPane.hidden){
            [self showPreviewPane];
            [self adjustIconsToVerticalCenter];
        }
        [self populatePreviewPaneWithImages];
    } else {
        if(!self.previewPane.hidden){
            [self hidePreviewPane];
            [self adjustIconsToVerticalCenter];
        }
    }
}

- (void) removePreviewImage:(UITapGestureRecognizer *)removeRecognizer
{
    UIView *crossImageView = removeRecognizer.view;
    
    NSInteger imageIndexToRemove = crossImageView.tag - kFirstPreviewToRemoveTag;
    [self.pickedImages removeObjectAtIndex:imageIndexToRemove];
    
    [self refreshPreviewPane];
}

- (void) showPreviewPane
{
    [self changeHeightOfBorderViewOn:self.previewPane.frame.size.height];
    self.previewPane.hidden = NO;
}

- (void) hidePreviewPane
{
    [self changeHeightOfBorderViewOn:-self.previewPane.frame.size.height];
    self.previewPane.hidden = YES;
}

- (void) changeHeightOfBorderViewOn:(CGFloat) heightDiff
{
    CGRect expandedSelfFrame = self.frame;
    expandedSelfFrame.size.height += heightDiff;
    expandedSelfFrame.origin.y -= heightDiff;
    self.frame = expandedSelfFrame;
    
    self.backgroundView.frame = self.bounds;

    _auxiliaryToolbar.frame = CGRectOffset(_auxiliaryToolbar.frame, 0.0f, heightDiff);

    CGRect shiftedDownTextViewFrame = self.textView.frame;
    shiftedDownTextViewFrame.origin.y += heightDiff;
    self.textView.frame = shiftedDownTextViewFrame;
    
    CGRect expandedBorderViewFrame = self.borderView.frame;
    expandedBorderViewFrame.size.height += heightDiff;
    self.borderView.frame = expandedBorderViewFrame;
}

#pragma mark mFWInputToolbar views' constructing methods
- (UIView *) constructPreviewPane
{
    CGRect previewPaneFrame = CGRectMake(0.0f,
                                         0.0f,
                                         self.borderView.frame.size.width,
                                         kPreviewPaneHeight);
    
    UIView *previewPaneView = [[UIView alloc] initWithFrame:previewPaneFrame];
    previewPaneView.backgroundColor = [UIColor clearColor];
    
    UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(kPreviewImageLeftPadding,
                                                               (kPreviewPaneHeight - kPreviewPaneSpacerHeight),
                                                               previewPaneFrame.size.width - 2 * kPreviewImageLeftPadding,
                                                               kPreviewPaneSpacerHeight)];
    
    spacer.backgroundColor = kPreviewPaneSpacerColor;
    [previewPaneView addSubview:spacer];
    
    self.previewPaneSpacerView = spacer;
    
    CGRect scrollViewFrame = CGRectMake(0.0f, kPreviewImageTopPadding, previewPaneFrame.size.width, kPreviewImageWidthAndHeight);
    
    UIScrollView *paneScrollView = [[UIScrollView alloc] initWithFrame:scrollViewFrame];
    paneScrollView.contentSize = CGSizeMake(0.0, scrollViewFrame.size.height);
    
    [previewPaneView addSubview:paneScrollView];
    paneScrollView.scrollEnabled = YES;
    paneScrollView.pagingEnabled = YES;
    
    paneScrollView.clipsToBounds = NO;
    
    self.previewPaneScrollView = paneScrollView;
    
    if(self.pickedImages.count){
        [self populatePreviewPaneWithImages];
    }
    
    previewPaneView.backgroundColor = [UIColor clearColor];
    
    //_auxiliaryToolbar.frame = CGRectOffset(_auxiliaryToolbar.frame, 0.0f, kPreviewPaneHeight);
    return previewPaneView;
}


-(UIView *) constructAuxiliaryToolbar
{
    CGRect auxiliaryToolbarFrame = (CGRect){0.0f, kInputToolbarInitialHeight, self.frame.size.width, kAuxiliaryToolbarHeight};
    UIView *auxiliaryToolbar = [[UIView alloc] initWithFrame:auxiliaryToolbarFrame];
    
    auxiliaryToolbar.backgroundColor = kInputToolBarColor;
    
    UIView *borderView = [self makeHorizontalBorder];
    [auxiliaryToolbar addSubview:borderView];
    
    
    CGRect pickFromGalleryImageViewFrame = (CGRect){0.0f, 0.0f, kAuxiliaryToolbarHeight, kAuxiliaryToolbarHeight};
    self.pickFromGalleryImageView = [[UIImageView alloc] initWithFrame:pickFromGalleryImageViewFrame];
    _pickFromGalleryImageView.contentMode = UIViewContentModeCenter;
    _pickFromGalleryImageView.image = [UIImage imageNamed:resourceFromBundle(@"mFW_gallery")];
    CGPoint galleryIconImageViewCenter = (CGPoint){self.frame.size.width / 2, kAuxiliaryToolbarHeight / 2};
    _pickFromGalleryImageView.center = galleryIconImageViewCenter;
    
    UITapGestureRecognizer *pickFromGalleryGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pickFromGallery:)];
    [self.pickFromGalleryImageView addGestureRecognizer:pickFromGalleryGestureRecognizer];
    
    [auxiliaryToolbar addSubview:_pickFromGalleryImageView];
    
    
    CGRect takeAPhotoImageViewFrame = pickFromGalleryImageViewFrame;
    CGPoint takeAPhotoImageViewCenter = galleryIconImageViewCenter;
    takeAPhotoImageViewCenter.x -= kAuxiliaryToolbarSpaceBetweenIconCenters;
    self.takeAPhotoImageView = [[UIImageView alloc] initWithFrame:takeAPhotoImageViewFrame];
    _takeAPhotoImageView.contentMode = UIViewContentModeCenter;
    _takeAPhotoImageView.center = takeAPhotoImageViewCenter;
    _takeAPhotoImageView.image = [UIImage imageNamed:resourceFromBundle(@"mFW_photo")];
    
    UITapGestureRecognizer *takeAPhotoGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takeAPhoto:)];
    [self.takeAPhotoImageView addGestureRecognizer:takeAPhotoGestureRecognizer];
    
    [auxiliaryToolbar addSubview:_takeAPhotoImageView];
    
    CGRect toggleGeolocationImageViewFrame = pickFromGalleryImageViewFrame;
    CGPoint toggleGeolocationImageViewCenter = galleryIconImageViewCenter;
    toggleGeolocationImageViewCenter.x += kAuxiliaryToolbarSpaceBetweenIconCenters;
    self.toggleGeolocationImageView = [[UIImageView alloc] initWithFrame:toggleGeolocationImageViewFrame];
    _toggleGeolocationImageView.center = toggleGeolocationImageViewCenter;
    _toggleGeolocationImageView.image = [UIImage imageNamed:resourceFromBundle(@"mFW_geolocation_off")];
    _toggleGeolocationImageView.highlightedImage = [UIImage imageNamed:resourceFromBundle(@"mFW_geolocation_on")];
    _toggleGeolocationImageView.contentMode = UIViewContentModeCenter;
    _toggleGeolocationImageView.highlighted = NO;
    
    UITapGestureRecognizer *toggleGeolocationGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleGeolocation:)];
    [self.toggleGeolocationImageView addGestureRecognizer:toggleGeolocationGestureRecognizer];
    
    [auxiliaryToolbar addSubview:_toggleGeolocationImageView];
    
    
    _takeAPhotoImageView.userInteractionEnabled = YES;
    _pickFromGalleryImageView.userInteractionEnabled = YES;
    _toggleGeolocationImageView.userInteractionEnabled = YES;
    
    auxiliaryToolbar.userInteractionEnabled = YES;
    
    auxiliaryToolbar.hidden = YES;
    
    return auxiliaryToolbar;
}

-(UIView *) makeHorizontalBorder
{
    CGRect borderFrame = CGRectMake(0.0f, -kBorderHeight, self.frame.size.width, kBorderHeight);
    UIView *border = [[UIView alloc] initWithFrame:borderFrame];
    border.backgroundColor = kBorderColor;
    
    return border;
}



#pragma mark mFWInputToolbarDelegate methods
-(void)indicateGeolocationIsEnabled:(BOOL)isEnabled
{
    self.toggleGeolocationImageView.highlighted = isEnabled;
}

-(CGFloat)trueToolbarHeight
{
    CGFloat trueHeight = self.frame.size.height;
    
    if(!self.auxiliaryToolbar.hidden){
        trueHeight += self.auxiliaryToolbar.frame.size.height;
    }
    
    return trueHeight;
}


@end
