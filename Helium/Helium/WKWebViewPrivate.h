//
//  Test.h
//  Helium Lift
//
//  Modified by Justin Mitchell on 7/12/15.
//  Copyright © 2015-2019 Justin Mitchell. All rights reserved.
//

@import WebKit;

@interface WKWebView (Privates)

@property (copy, setter=_setCustomUserAgent:) NSString *_customUserAgent;

@property (nonatomic, readonly) NSString *_userAgent;

@end
