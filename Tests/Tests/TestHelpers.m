// TestHelpers.m
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

#import "TestHelpers.h"
#import <AFNetworking/AFURLConnectionOperation.h>
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>


#pragma mark - Private Test Classes

@interface TestRedirectedNotificationObject : NSObject

+(instancetype)testRedirectedNotificationObjectWithRequest:(NSURLRequest *)request;

@property (copy) NSURLRequest *request;
@property (copy) NSURLResponse *response;

@end

@implementation TestRedirectedNotificationObject

+(instancetype)testRedirectedNotificationObjectWithRequest:(NSURLRequest *)request {
    TestRedirectedNotificationObject *instance = [[self alloc] init];

    instance.request = request;

    return instance;
}

- (NSString *)responseString {
    return @"response";
}

@end

@interface TestNotificationObject : NSURLSessionTask

+ (instancetype)testNotificationObject;
+ (instancetype)testNotificationObjectWithOriginalRequest:(NSURLRequest *)request;
+ (instancetype)testNotificationObjectWithOriginalRequest:(NSURLRequest *)request response:(NSURLResponse *)response;
+ (instancetype)testNotificationObjectWithOriginalRequest:(NSURLRequest *)request response:(NSURLResponse *)response error:(NSError *)error;

@property (copy) NSURLRequest *originalRequest;
@property (copy) NSURLResponse *response;
@property (copy) NSError *error;

@end

@implementation TestNotificationObject

@synthesize originalRequest, response, error;

+ (instancetype)testNotificationObject {
    return [self testNotificationObjectWithOriginalRequest:nil];
}

+ (instancetype)testNotificationObjectWithOriginalRequest:(NSURLRequest *)request {
    return [self testNotificationObjectWithOriginalRequest:request response:nil];
}

+ (instancetype)testNotificationObjectWithOriginalRequest:(NSURLRequest *)request response:(NSURLResponse *)response {
    return [self testNotificationObjectWithOriginalRequest:request response:response error:nil];
}

+ (instancetype)testNotificationObjectWithOriginalRequest:(NSURLRequest *)request response:(NSURLResponse *)response error:(NSError *)error {
    TestNotificationObject *instance = [[self alloc] init];

    instance.originalRequest = request;
    instance.response = response;
    instance.error = error;

    return instance;
}

- (NSString *)responseString {
    return @"response";
}

@end

@interface TestResponse: NSHTTPURLResponse

@property (readwrite) NSInteger statusCode;
@property (readwrite, copy) NSDictionary *allHeaderFields;

@end

@implementation TestResponse

@synthesize statusCode, allHeaderFields;

@end

#pragma mark - Private Functions

static NSURLRequest *generateRequest(NSURL *url) {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setValue:HEADER_VALUE forHTTPHeaderField:HEADER_KEY];
    request.HTTPBody = BODY;
    return request;
}

static NSURLResponse *generateResponse(NSURL *url) {
    TestResponse *response = [[TestResponse alloc] initWithURL:url MIMEType:nil expectedContentLength:0 textEncodingName:nil];
    response.statusCode = 200;
    response.allHeaderFields = @{ HEADER_KEY: HEADER_VALUE };
    return response;
}

#pragma mark - Public Methods

id postEmptyRequestToLogger(AFNetworkActivityLogger *logger) {
    TestNotificationObject *object = [TestNotificationObject testNotificationObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:object];
    return object;
}

id postRequestToLogger(AFNetworkActivityLogger *logger, NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = generateRequest(url);

    TestNotificationObject *object = [TestNotificationObject testNotificationObjectWithOriginalRequest:request];
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:object];
    return object;
}

id postRedirectedRequestToLogger(AFNetworkActivityLogger *logger, NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = generateRequest(url);

    TestRedirectedNotificationObject *object = [TestRedirectedNotificationObject testRedirectedNotificationObjectWithRequest:request];
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:object];
    return object;
}

void postResponseToLogger(AFNetworkActivityLogger *logger, id sentObject, NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];

    TestNotificationObject *object = sentObject;
    object.response = generateResponse(url);

    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:object];
}

void postFreshResponseToLogger(AFNetworkActivityLogger *logger, NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLResponse *response = generateResponse(url);

    TestNotificationObject *object = [TestNotificationObject testNotificationObjectWithOriginalRequest:nil response:response];
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:object];
}

void postEmptyResponseToLogger(AFNetworkActivityLogger *logger) {
    TestNotificationObject *object = [TestNotificationObject testNotificationObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:object];
}

void postFreshErrorResponseToLogger(AFNetworkActivityLogger *logger, NSString *urlString) {
    return postErrorResponseToLogger(logger, nil, urlString);
}

void postErrorResponseToLogger(AFNetworkActivityLogger *logger, id sentObject, NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];

    TestNotificationObject *object = sentObject;
    object.response = generateResponse(url);

    NSURLRequest *request = generateRequest(url);
    NSURLResponse *response = generateResponse(url);
    NSError *error = [NSError errorWithDomain:@"testing" code:0 userInfo:nil];

    if (object == nil) {
        object = [TestNotificationObject testNotificationObjectWithOriginalRequest:request response:response error:error];
    }

    object.originalRequest = request;
    object.response = response;
    object.error = error;

    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:object];
}

@interface TestURLConnectionOperation : AFURLConnectionOperation

@property (readwrite, nonatomic, strong) NSError *error;

@end

@implementation TestURLConnectionOperation

@synthesize error;

@end

void postConnectionOperationErrorToLogger(AFNetworkActivityLogger *logger, NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *resquest = generateRequest(url);

    NSError *error = [NSError errorWithDomain:@"testing" code:0 userInfo:nil];

    TestURLConnectionOperation *object = [[TestURLConnectionOperation alloc] initWithRequest:resquest];
    object.error = error;

    return postErrorResponseToLogger(logger, nil, urlString);
}
