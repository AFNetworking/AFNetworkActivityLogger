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

@interface AFNetworkActivityLogger () <AFNetworkActivityLoggerLogDelegate>
@end

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
    self.logDelegate = self;

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

    NSString *body = nil;
    if ([request HTTPBody]) {
        body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    }

    NSString *message = nil;
    AFHTTPRequestLoggerLevel messageLevel = AFLoggerLevelOff;
    switch (self.level) {
        case AFLoggerLevelDebug:
            messageLevel = AFLoggerLevelDebug;
            message = [NSString stringWithFormat:@"%@ '%@': %@ %@", [request HTTPMethod], [[request URL] absoluteString], [request allHTTPHeaderFields], body];
            break;
        case AFLoggerLevelInfo:
            messageLevel = AFLoggerLevelInfo;
            message = [NSString stringWithFormat:@"%@ '%@'", [request HTTPMethod], [[request URL] absoluteString]];
            break;
        default:
            break;
    }
    if (message) {
        [self.logDelegate afNetworkLog:message level:messageLevel error:nil];
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
        responseStatusCode = (NSUInteger)[(NSHTTPURLResponse *)response statusCode];
        responseHeaderFields = [(NSHTTPURLResponse *)response allHeaderFields];
    }

    id responseObject = nil;
    if ([[notification object] respondsToSelector:@selector(responseString)]) {
        responseObject = [[notification object] responseString];
    } else if (notification.userInfo) {
        responseObject = notification.userInfo[AFNetworkingTaskDidCompleteSerializedResponseKey];
    }

    NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:objc_getAssociatedObject(notification.object, AFNetworkRequestStartDate)];

    NSString *message = nil;
    AFHTTPRequestLoggerLevel messageLevel = AFLoggerLevelOff;
    if (error) {
        switch (self.level) {
            case AFLoggerLevelOff: /* and AFLoggerLevelFatal */
                break;
            default:
                messageLevel = AFLoggerLevelError;
                message = [NSString stringWithFormat:@"[Error] %@ '%@' (%ld) [%.04f s]: %@", [request HTTPMethod], [[response URL] absoluteString], (long)responseStatusCode, elapsedTime, error];
                break;
        }
    } else {
        switch (self.level) {
            case AFLoggerLevelDebug:
                messageLevel = AFLoggerLevelDebug;
                message = [NSString stringWithFormat:@"%ld '%@' [%.04f s]: %@ %@", (long)responseStatusCode, [[response URL] absoluteString], elapsedTime, responseHeaderFields, responseObject];
                break;
            case AFLoggerLevelInfo:
                messageLevel = AFLoggerLevelInfo;
                message = [NSString stringWithFormat:@"%ld '%@' [%.04f s]", (long)responseStatusCode, [[response URL] absoluteString], elapsedTime];
                break;
            default:
                break;
        }
    }
    if (message) {
        [self.logDelegate afNetworkLog:message level:messageLevel error:error];
    }
}

#pragma mark - AFNetworkActivityLoggerLogDelegate

- (void)afNetworkLog:(NSString *)logMessage level:(AFHTTPRequestLoggerLevel)logLevel error:(NSError *)logError
{
    if (self.level <= logLevel) {
        NSLog(logMessage);
    }
}

@end
