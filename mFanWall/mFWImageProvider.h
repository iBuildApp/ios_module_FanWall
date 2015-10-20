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

#import <Foundation/Foundation.h>
#import "mFWImageConsumer.h"

/**
 * Presents image picking dialog and provide an image either from photo gallery,
 * or by taking it with camera (if available).
*/
@interface mFWImageProvider : NSObject <UIActionSheetDelegate,
                                        UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate>

/**
 * Object conforming to mFWImageConsumer protocol.
 *
 * @see mFWImageConsumer
 */
@property(nonatomic, unsafe_unretained) id<mFWImageConsumer> imageConsumer;

/**
 * View controller to present dialog with picking options on.
 */
@property(nonatomic, unsafe_unretained) UIViewController *presentingController;

/**
 * Initializes image provider with consumer and presenter.
 *
 * @see mFWImageConsumer
 * @see presentingController
 */
- (instancetype) initWithImageConsumer:(id<mFWImageConsumer>)consumer
                    andDialogPresenter:(UIViewController *)presenter;

/**
 * Presents dialog with image picking options: camera or gallery.
 */
- (void) displayDialog;

/**
 * Force imageProvider to provide an image from Gallery.
 */
- (void) provideAnImageFromGallery;

/**
 * Force imageProvider to provide an image with Camera.
 */
- (void) provideAnImageWithCamera;

@end
