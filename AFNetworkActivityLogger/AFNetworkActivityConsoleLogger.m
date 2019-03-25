// AFNetworkActivityConsoleLogger.h
//
// Copyright (c) 2018 AFNetworking (http://afnetworking.com/)
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

#import "AFNetworkActivityConsoleLogger.h"

@implementation AFNetworkActivityConsoleLogger

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.level = AFLoggerLevelInfo;
    
    return self;
}


- (void)URLSessionTaskDidStart:(NSURLSessionTask *)task {
    NSURLRequest *request = task.originalRequest;
    
    NSString *requestMethod = [request HTTPMethod];
    
    NSURL *url = [request URL];
    
    NSString *urlPath = [url path];
    NSString *query = [url query];
    if (query) {
        urlPath = [NSString stringWithFormat:@"%@?%@", urlPath, query];
    }
    
    NSString *portStr;
    NSNumber *port = [url port];
    if (port) {
        portStr = [NSString stringWithFormat:@"%@", port];
    } else {
        portStr = @"80";
    }
    NSString *host = [NSString stringWithFormat:@"%@://%@:%@", [url scheme], [url host], portStr];
    
    NSString *format = @"\n--------------------------------------------------\n%@ %@ HTTP/1.1\nHost: %@\n";
    NSString *str = [NSString stringWithFormat:format, requestMethod, urlPath, host];
    
    NSDictionary *headers = [request allHTTPHeaderFields];
    NSArray *keys = headers.allKeys;
    for (int i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSString *value = [headers valueForKey:key];
        str = [NSString stringWithFormat:@"%@%@: %@\n", str, key, value];
    }
    
    NSString *bodyStr;
    NSData *requestBody = [request HTTPBody];
    if (requestBody) {
        bodyStr = [[NSString alloc] initWithData:requestBody encoding:NSUTF8StringEncoding];
    } else {
        bodyStr = @"";
    }
    
    str = [NSString stringWithFormat:@"%@\n%@\n--------------------------------------------------\n", str, bodyStr];
    
    NSLog(@"%@", str);
}

- (void)URLSessionTaskDidFinish:(NSURLSessionTask *)task withResponseObject:(id)responseObject inElapsedTime:(NSTimeInterval )elapsedTime withError:(NSError *)error {
    
    NSString *str = @"\n----------------------------------------------------------------\n";
    
    NSString *url = [[task.response URL] absoluteString];
    
    str = [NSString stringWithFormat:@"%@%@--->\nHTTP/1.1 ", str, url];
    
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        
        NSUInteger responseStatusCode = (NSUInteger)[response statusCode];
        str = [NSString stringWithFormat:@"%@%lu\n", str, responseStatusCode];
        
        NSString *contentType = nil;
        NSDictionary *responseHeaderFields = [response allHeaderFields];
        if (responseHeaderFields) {
            NSArray *fields = [responseHeaderFields allKeys];
            for (int i = 0; i < fields.count; i++) {
                NSString *key = fields[i];
                NSString *value = [responseHeaderFields valueForKey:key];
                str = [NSString stringWithFormat:@"%@%@: %@\n", str, key, value];
                if ([@"Content-Type" isEqualToString:key]) {
                    contentType = value;
                }
            }
        }
        
        id responseBody = responseObject;
        
        if(contentType && ([contentType containsString:@"application/json"]
                           || [contentType containsString:@"application/xml"]
                           || [contentType containsString:@"application/x-www-form-urlencoded"]
                           || [contentType containsString:@"text/html"])) {
            if ([responseObject isKindOfClass:[NSData class]]) {
                responseBody = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
                if ([NSJSONSerialization isValidJSONObject:responseObject]) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
                    if (error) {
                        NSLog(@"Error:%@" , error);
                    } else {
                        responseBody =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                }
            }
        }
        
        str = [NSString stringWithFormat:@"%@%@\n------------------------------------------------\n", str, responseBody];
    }
    
    NSLog(@"%@", str);
}

@end
