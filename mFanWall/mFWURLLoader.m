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

#import "mFWURLLoader.h"
#import "SBJSON.h"

@interface mFWURLLoader()
  @property (nonatomic, strong) NSURLConnection          *connection;
  @property (nonatomic, strong) NSMutableData            *receivedData;
  @property (nonatomic, strong) mFWURLLoader             *this;         // to retain object (self do not to die)
  @property (nonatomic, copy  ) mFWURLLoaderSuccessBlock  successBlock;
  @property (nonatomic, copy  ) mFWURLLoaderFailureBlock  failureBlock;
@end


@implementation mFWURLLoader
@synthesize connection = _connection,
                  this = _this,
          receivedData = _receivedData,
          successBlock = _successBlock,
          failureBlock = _failureBlock;

- (void)initialize
{
  _connection   = nil;
  _receivedData = nil;
  _successBlock = nil;
  _failureBlock = nil;
  _this         = nil;
}

- (id)init
{
  self = [super init];
  if ( self )
  {
    [self initialize];
  }
  return self;
}


- (id)initWithRequest:(NSURLRequest *)request
              success:(mFWURLLoaderSuccessBlock )success_
              failure:(mFWURLLoaderFailureBlock )failure_
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    [self startWithRequest:request
                   success:success_
                   failure:failure_];
  }
  return self;
}

- (void)startWithRequest:(NSURLRequest *)request
                 success:(mFWURLLoaderSuccessBlock )success_
                 failure:(mFWURLLoaderFailureBlock )failure_
{
  NSURLConnection *con = [[[NSURLConnection alloc] initWithRequest:request
                                                          delegate:self] autorelease];
  if ( con )
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.successBlock = success_;
    self.failureBlock = failure_;
    self.connection   = con;
    // save your self !!!
    self.this = self;
  }
  else
  {
    // Inform the user that the connection failed.
    if ( failure_ )
      failure_( [NSError errorWithDomain:@"couldn't create NSURLConnection object." code:1 userInfo:nil] );
  }
}

-(void)dealloc
{
  [self cancel];
  [super dealloc];
}

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  self.receivedData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  // call the succes block with received data
  if ( self.successBlock )
  {
    NSDictionary *serverResponse = nil;
    if ( [self.receivedData length] )
    {
      SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
      serverResponse = [jsonParser objectWithData:self.receivedData];
      [jsonParser release];
    }
    self.successBlock( self.receivedData, serverResponse );
  }
  self.successBlock = nil;
  self.failureBlock = nil;
  self.receivedData = nil;
  self.connection   = nil;
  // self kill...
  self.this         = nil;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  if ( self.failureBlock )
    self.failureBlock(error);
  self.successBlock = nil;
  self.failureBlock = nil;
  self.receivedData = nil;
  self.connection   = nil;
  // self kill...
  self.this         = nil;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)cancel
{
  [self.connection cancel];
  /*
   * After loading operation cancels, connectionDidFinishLoading will be called with STALE data.
   * So we make an artificial call of connection:didFailWithError:
   */
  NSError *error = [NSError errorWithDomain:@"connection canceled by user" code:NSURLErrorCancelled userInfo:nil];
  [self connection:self.connection didFailWithError:error];
}

@end
