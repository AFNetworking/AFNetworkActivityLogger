// Tests.m
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

#import <XCTest/XCTest.h>
#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <AFNetworking/AFURLConnectionOperation.h>
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>

#import "TestHelpers.h"

SpecBegin(AFNetworkActivityLogger)

__block BOOL logged;
__block AFNetworkActivityLogger *subject;

beforeEach(^{
    subject = [[AFNetworkActivityLogger alloc] init];
});

it(@"has a default level of info", ^{
    expect(subject.level).to.equal(AFLoggerLevelInfo);
});

describe(@"logging", ^{
    beforeEach(^{
        logged = NO;

        subject.loggingBlock = ^(NSString *message) {
            logged = YES;
        };
    });

    it(@"doesn't log when not started", ^{
        postRequestToLogger(subject, TEST_URL);
        expect(logged).to.beFalsy();
    });

    it(@"logs once started", ^{
        [subject startLogging];
        postRequestToLogger(subject, TEST_URL);
        expect(logged).to.beTruthy();
    });

    it(@"doesn't log when stopped after being started", ^{
        [subject startLogging];
        [subject stopLogging];
        postRequestToLogger(subject, TEST_URL);
        expect(logged).to.beFalsy();
    });

    it(@"logs errors", ^{
        [subject startLogging];
        postFreshErrorResponseToLogger(subject, TEST_URL);
        expect(logged).to.beTruthy();
    });

    describe(@"when logging set to off level and logging is started", ^{
        beforeEach(^{
            subject.level = AFLoggerLevelOff;
            [subject startLogging];
        });

        it(@"doesn't log errors", ^{
            postFreshErrorResponseToLogger(subject, TEST_URL);
            expect(logged).to.beFalsy();
        });
    });
});

describe(@"started", ^{
    __block NSString *message;

    beforeEach(^{
        [subject startLogging];

        message = nil;
        logged = NO;

        subject.loggingBlock = ^(NSString *sentMessage) {
            message = sentMessage;
            logged = YES;
        };
    });

    it(@"it logs errors", ^{
        id object = postRequestToLogger(subject, TEST_URL);
        postErrorResponseToLogger(subject, object, TEST_URL);
        expect(message).to.match(@"\\[Error\\] GET 'http:\\/\\/example\\.com' \\(200\\) \\[[0-9].[0-9]{4} s\\]: Error Domain=testing Code=0 \"The operation couldn’t be completed\\. \\(testing error 0\\.\\)\"");
    });

    describe(@"on debug", ^{
        beforeEach(^{
            subject.level = AFLoggerLevelDebug;
        });

        it(@"logs requests verbosely", ^{
            postRequestToLogger(subject, TEST_URL);
            expect(message).to.match(@"GET 'http:\\/\\/example\\.com': \\{\\n    \"header_key\" = \"header_value\";\\n\\} request_body");
        });

        it(@"logs responses verbosely", ^{
            id object = postRequestToLogger(subject, TEST_URL);
            postResponseToLogger(subject, object, TEST_URL);
            expect(message).to.match(@"200 'http:\\/\\/example\\.com' \\[[0-9]+\\.[0-9]{4} s\\]: \\{\\n    \"header_key\" = \"header_value\";\\n\\} response");
        });
    });

    describe(@"on info", ^{
        it(@"logs requests succinctly", ^{
            postRequestToLogger(subject, TEST_URL);
            expect(message).to.match(@"GET 'http:\\/\\/example\\.com'");
        });

        it(@"logs responses succinctly", ^{
            id object = postRequestToLogger(subject, TEST_URL);
            postResponseToLogger(subject, object, TEST_URL);
            expect(message).to.match(@"200 'http:\\/\\/example\\.com' \\[[0-9].[0-9]{4} s\\]");
        });
    });

    sharedExamplesFor(@"an off level", ^(NSDictionary *data) {
        beforeEach(^{
            subject.level = (AFHTTPRequestLoggerLevel)[data[@"level"] unsignedIntegerValue];
        });

        it(@"shouldn't log requests", ^{
            postRequestToLogger(subject, TEST_URL);
            expect(logged).to.beFalsy();
        });

        it(@"shouldn't log responses", ^{
            postFreshResponseToLogger(subject, TEST_URL);
            expect(logged).to.beFalsy();
        });

        it(@"it shouldn't log errors", ^{
            postFreshErrorResponseToLogger(subject, TEST_URL);
            expect(logged).to.beFalsy();
        });
    });

    itShouldBehaveLike(@"an off level", @{ @"level": @(AFLoggerLevelOff) });
    itShouldBehaveLike(@"an off level", @{ @"level": @(AFLoggerLevelFatal) });

    sharedExamplesFor(@"a non-info, non-debug level", ^(NSDictionary *data) {
        beforeEach(^{
            subject.level = (AFHTTPRequestLoggerLevel)[data[@"level"] unsignedIntegerValue];
        });

        it(@"shouldn't log requests", ^{
            postRequestToLogger(subject, TEST_URL);
            expect(logged).to.beFalsy();
        });

        it(@"shouldn't log responses", ^{
            postFreshResponseToLogger(subject, TEST_URL);
            expect(logged).to.beFalsy();
        });

        it(@"it should log errors", ^{
            postFreshErrorResponseToLogger(subject, TEST_URL);
            expect(logged).to.beTruthy();
        });
    });

    itShouldBehaveLike(@"a non-info, non-debug level", @{ @"level": @(AFLoggerLevelWarn) });
    itShouldBehaveLike(@"a non-info, non-debug level", @{ @"level": @(AFLoggerLevelError) });

    it(@"doesn't log empty requests", ^{
        postEmptyRequestToLogger(subject);
        expect(logged).to.beFalsy();
    });

    it(@"logs responses with missing requests", ^{
        postFreshResponseToLogger(subject, TEST_URL);
        expect(logged).to.beTruthy();
    });

    it(@"doesn't log with missing requests and responses", ^{
        postEmptyResponseToLogger(subject);
        expect(logged).to.beFalsy();
    });


    describe(@"with a URL predicate", ^{
        NSString *matchingURL = @"http://nshipster.com";
        beforeEach(^{
            subject.filterPredicate = [NSPredicate predicateWithFormat:@"URL.absoluteString = %@", matchingURL];
        });

        it(@"logs requests with non-matching URLs", ^{
            postRequestToLogger(subject, TEST_URL);
            expect(logged).to.beTruthy();
        });

        it(@"logs responses with non-matching URLs", ^{
            postFreshResponseToLogger(subject, TEST_URL);
            expect(logged).to.beTruthy();
        });

        it(@"doesn't log requests with matching URLs", ^{
            postRequestToLogger(subject, matchingURL);
            expect(logged).to.beFalsy();
        });

        it(@"doesn't log responses with matching URLs", ^{
            id object = postRequestToLogger(subject, matchingURL);
            postResponseToLogger(subject, object, matchingURL);
            expect(logged).to.beFalsy();
        });
    });

    it(@"specifies elapsed time", ^{
        id object = postRequestToLogger(subject, TEST_URL);
        sleep(1);
        postResponseToLogger(subject, object, TEST_URL);

        NSString *durationString = [message substringWithRange:NSMakeRange(26, 6)];
        CGFloat duration = [durationString floatValue];
        expect(duration).to.beGreaterThanOrEqualTo(1.0);
    });

    describe(@"request is specified and originalRequest is not available", ^{
        it(@"logs requests", ^{
            postRedirectedRequestToLogger(subject, TEST_URL);
            expect(message).to.match(@"GET 'http:\\/\\/example\\.com'");
        });

        it(@"logs responses", ^{
            id object = postRedirectedRequestToLogger(subject, TEST_URL);
            postResponseToLogger(subject, object, @"http://new.url");
            expect(message).to.match(@"200 'http:\\/\\/new\\.url' \\[[0-9].[0-9]{4} s\\]");
        });
    });

    it(@"uses the AFURLConnectionOperation notification object's error property if specified", ^{
        postConnectionOperationErrorToLogger(subject, TEST_URL);
        expect(message).to.match(@"\\[Error\\] GET 'http:\\/\\/example\\.com' \\(200\\) \\[nan s\\]: Error Domain=testing Code=0 \"The operation couldn’t be completed\\. \\(testing error 0\\.\\)\"");
    });
});

pending(@"logs to NSLog when no loggingBlock is specified.");

SpecEnd
