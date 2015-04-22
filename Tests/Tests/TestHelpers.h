// TestHelpers.h
//
// Copyright (c) 2015 AFNetworking (http://afnetworking.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@class AFNetworkActivityLogger;

#define TEST_URL @"http://example.com"
#define BODY_STRING @"request_body"
#define BODY [BODY_STRING dataUsingEncoding:NSUTF8StringEncoding]
#define HEADER_KEY @"header_key"
#define HEADER_VALUE @"header_value"

extern id postEmptyRequestToLogger(AFNetworkActivityLogger *logger);
extern id postRequestToLogger(AFNetworkActivityLogger *logger, NSString *urlString);
extern id postRedirectedRequestToLogger(AFNetworkActivityLogger *logger, NSString *urlString);
extern void postResponseToLogger(AFNetworkActivityLogger *logger, id sentObject, NSString *urlString);
extern void postFreshResponseToLogger(AFNetworkActivityLogger *logger, NSString *urlString);
extern void postEmptyResponseToLogger(AFNetworkActivityLogger *logger);
extern void postFreshErrorResponseToLogger(AFNetworkActivityLogger *logger, NSString *urlString);
extern void postErrorResponseToLogger(AFNetworkActivityLogger *logger, id sentObject, NSString *urlString);
extern void postConnectionOperationErrorToLogger(AFNetworkActivityLogger *logger, NSString *urlString);
