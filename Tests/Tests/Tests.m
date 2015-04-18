//  Tests.m
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

#import <XCTest/XCTest.h>
#import <Specta/Specta.h>
#import <stdarg.h>
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>

SpecBegin(AFNetworkActivityLogger)

__block AFNetworkActivityLogger *subject;

beforeEach(^{
    subject = [AFNetworkActivityLogger sharedLogger];
});

pending(@"has a default level of info");
pending(@"only logs when started");
pending(@"stops logging after being stopped");

describe(@"when logging set to off level", ^{
    pending(@"doesn't log errors");
});

describe(@"on debug", ^{
    pending(@"logs requests verbosely");
    pending(@"logs responses verbosely");
});

describe(@"on info", ^{
    pending(@"logs requests succinctly");
    pending(@"logs responses succinctly");
});

describe(@"on non-info, non-debug log levels", ^{
    pending(@"doesn't log at all");
});

describe(@"missing requests", ^{
    pending(@"doesn't log requests");
    pending(@"still logs responses");
});

describe(@"missing requests and responses", ^{
    pending(@"doesn't log responses");
});

pending(@"filters out based on URL predicates");
pending(@"specifies elapsed time");

SpecEnd
