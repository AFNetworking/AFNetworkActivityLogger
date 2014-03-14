// AFNetworkActivityLogger.h
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com/)
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

#import "AFNetworkActivityLogger.h"
#import "AFURLConnectionOperation.h"
#import "AFURLSessionManager.h"

#import <objc/runtime.h>

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    NSURLRequest *request = nil;
    if ([[notification object] isKindOfClass:[AFURLConnectionOperation class]]) {
        request = [(AFURLConnectionOperation *)[notification object] request];
    } else if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        request = [[notification object] originalRequest];
    }

    return request;
}

@implementation AFNetworkActivityLogger

+ (instancetype)sharedLogger {
    static AFNetworkActivityLogger *_sharedLogger = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[self alloc] init];
    });

    return _sharedLogger;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.level = AFLoggerLevelInfo;

    return self;
}

- (void)dealloc {
    [self stopLogging];
}

- (void)startLogging {
    [self stopLogging];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingOperationDidFinishNotification object:nil];

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingTaskDidResumeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingTaskDidCompleteNotification object:nil];
#endif
}

- (void)stopLogging {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSNotification

static void * AFNetworkRequestStartDate = &AFNetworkRequestStartDate;

- (void)networkRequestDidStart:(NSNotification *)notification {
    NSURLRequest *request = AFNetworkRequestFromNotification(notification);

    if (!request) {
        return;
    }

    if (request && self.filterPredicate && [self.filterPredicate evaluateWithObject:request]) {
        return;
    }

    objc_setAssociatedObject(notification.object, AFNetworkRequestStartDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    switch (self.level) {
        case AFLoggerLevelDebug:
            NSLog(@"%@ '%@': %@ %@", [request HTTPMethod], [[request URL] absoluteString], [request allHTTPHeaderFields], [self.class bodyToPrintForRequest:request]);
            break;
        case AFLoggerLevelInfo:
            NSLog(@"%@ '%@'", [request HTTPMethod], [[request URL] absoluteString]);
            break;
        default:
            break;
    }
}

- (void)networkRequestDidFinish:(NSNotification *)notification {
    NSURLRequest *request = AFNetworkRequestFromNotification(notification);
    NSURLResponse *response = [notification.object response];
    NSError *error = [notification.object error];

    if (!request && !response) {
        return;
    }

    if (request && self.filterPredicate && [self.filterPredicate evaluateWithObject:request]) {
        return;
    }

    NSUInteger responseStatusCode = 0;
    NSDictionary *responseHeaderFields = nil;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        responseStatusCode = [(NSHTTPURLResponse *)response statusCode];
        responseHeaderFields = [(NSHTTPURLResponse *)response allHeaderFields];
    }
    
    // Try to get the operation's response object first. If it's nil, get the response string.
    id objectToPrint = [self.class objectToPrintForOperation:notification.object];
    NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:objc_getAssociatedObject(notification.object, AFNetworkRequestStartDate)];

    if (error) {
        switch (self.level) {
            case AFLoggerLevelDebug:
            case AFLoggerLevelInfo:
            case AFLoggerLevelWarn:
            case AFLoggerLevelError:
                NSLog(@"[Error] %@ '%@' (%ld) [%.04f s]: %@", [request HTTPMethod], [[response URL] absoluteString], (long)responseStatusCode, elapsedTime, error);
            default:
                break;
        }
    } else {
        switch (self.level) {
            case AFLoggerLevelDebug:
                NSLog(@"%ld '%@' [%.04f s]: %@ %@", (long)responseStatusCode, [[response URL] absoluteString], elapsedTime, responseHeaderFields, objectToPrint);
                break;
            case AFLoggerLevelInfo:
                NSLog(@"%ld '%@' [%.04f s]", (long)responseStatusCode, [[response URL] absoluteString], elapsedTime);
                break;
            default:
                break;
        }
    }
}

#pragma mark - Object to print

+ (id)bodyToPrintForRequest:(NSURLRequest *)request {
    id body = nil;
    
    if ([request HTTPBody]) {
        // Parse the body as a string
        NSString *queryString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        
        // Parse a queryStringPairs from the http body
        NSArray *queryStringPairs = [queryString componentsSeparatedByString:@"&"];
        
        // Init queryStringPairsDictionary if needed
        NSMutableDictionary *queryStringPairsDictionary = (queryStringPairs.count) ? [[NSMutableDictionary alloc] init] : nil;
        
        // Decode URL-encoded query pairs
        for (NSString *queryStringPair in queryStringPairs) {
            NSArray *components = [queryStringPair componentsSeparatedByString:@"="];
            NSLog(@"%@", components);
            
            if (components.count>1) {
                id value = [[components[1]
                             stringByReplacingOccurrencesOfString:@"+" withString:@" "]
                            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                NSString *key = [queryStringPair componentsSeparatedByString:@"="][0];
                
                [queryStringPairsDictionary setValue:value
                                              forKey:key];
            }
        }
        
        body = (queryStringPairsDictionary.count) ? queryStringPairsDictionary : queryString;
    }
    
    return body;
}


+ (id)objectToPrintForOperation:(AFURLConnectionOperation*)operation {
    id objectToPrint = nil;
    
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([operation respondsToSelector:@selector(responseObject)])
        objectToPrint = [operation performSelector:@selector(responseObject)];
# pragma clang diagnostic pop
    
    else if ([operation respondsToSelector:@selector(responseString)])
        objectToPrint = [operation performSelector:@selector(responseString)];
    
    return objectToPrint;
}

@end
