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

typedef void(^mFWURLLoaderSuccessBlock)(NSData *result, NSDictionary *response);
typedef void(^mFWURLLoaderFailureBlock)(NSError *error);

/**
 * Asynchronous URL loader
 */
@interface mFWURLLoader : NSObject

/**
 * Cancells current request.
 */
-(void)cancel;

/**
 * Initializes a new instance of the loader and starts it with request and blocks specified.
 *
 * @see startWithRequest:success:failure:
 */
-(id)initWithRequest:(NSURLRequest *)request
             success:(mFWURLLoaderSuccessBlock )success_
             failure:(mFWURLLoaderFailureBlock )failure_;

/**
 * Starts loading the requests. 
 * Calls success_ and failure_ blocks in case of success_ and failure_ accordingly.
 *
 * @param success_ - success block.
 * @param failure_ - failure block.
 */
-(void)startWithRequest:(NSURLRequest *)request
                success:(mFWURLLoaderSuccessBlock )success_
                failure:(mFWURLLoaderFailureBlock )failure_;

@end



