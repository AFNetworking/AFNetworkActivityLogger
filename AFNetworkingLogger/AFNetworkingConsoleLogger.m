//AFNetworking: http://afnetworking.com
//
//HTTP1.1 Protocol Reference:
//https://tools.ietf.org/html/rfc2616
//https://www.w3.org/Protocols/rfc2616/rfc2616.txt

#import "AFNetworkingConsoleLogger.h"

@implementation AFNetworkingConsoleLogger

- (void)URLSessionTaskDidStart:(NSURLSessionTask *)task {
    NSString *str = @"\n----------------------------------------------------------------\n";
    
    NSURLRequest *request = task.originalRequest;
    
    NSURL *url = [request URL];
    
    NSString *path = [url path];
    if (path.length == 0) {
        path = @"/";
    }
    
    str = [NSString stringWithFormat:@"%@%@ %@", str, [request HTTPMethod], path];
    
    NSString *query = [url query];
    if (query) {
        str = [NSString stringWithFormat:@"%@?%@ HTTP/1.1\n", str, query];
    } else {
        str = [NSString stringWithFormat:@"%@ HTTP/1.1\n", str];
    }
    
    str = [NSString stringWithFormat:@"%@Host: %@", str, [url host]];
    
    NSNumber *port = [url port];
    if (port) {
        str = [NSString stringWithFormat:@"%@:%@\n", str, port];
    } else {
        str = [NSString stringWithFormat:@"%@\n", str];
    }
    
    NSDictionary *headers = [request allHTTPHeaderFields];
    NSArray *keys = headers.allKeys;
    for (int i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSString *value = [headers valueForKey:key];
        str = [NSString stringWithFormat:@"%@%@: %@\n", str, key, value];
    }
    
    NSData *requestBody = [request HTTPBody];
    if (requestBody) {
        NSString *bodyStr = [[NSString alloc] initWithData:requestBody encoding:NSUTF8StringEncoding];
        str = [NSString stringWithFormat:@"%@\n%@\n", str, bodyStr];
    }
    str = [NSString stringWithFormat:@"%@----------------------------------------------------------------\n", str];
    
    NSLog(@"%@", str);
}

- (void)URLSessionTaskDidFinish:(NSURLSessionTask *)task withResponseObject:(id)responseObject inElapsedTime:(NSTimeInterval )elapsedTime withError:(NSError *)error {
    
    NSString *str = @"\n----------------------------------------------------------------\n";
    
    NSString *url = [[task.response URL] absoluteString];
    str = [NSString stringWithFormat:@"%@%@--->\n\n", str, url];
    
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        
        NSUInteger responseStatusCode = (NSUInteger)[response statusCode];
        NSString *reason = [self getReasonByStatusCode:responseStatusCode];
        
        str = [NSString stringWithFormat:@"%@HTTP/1.1 %lu %@\n", str, responseStatusCode, reason];
        
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
        
        if (responseObject) {
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
            str = [NSString stringWithFormat:@"%@\n%@\n", str, responseBody];
        }
        str = [NSString stringWithFormat:@"%@----------------------------------------------------------------\n", str];
    }
    
    NSLog(@"responseBody = %@", str);
}

- (NSString*) getReasonByStatusCode:(NSUInteger)statusCode {
    switch (statusCode) {
        case 100: return @"Continue";
        case 101: return @"Switching Protocols";
            
        case 200: return @"OK";
        case 201: return @"Created";
        case 202: return @"Accepted";
        case 203: return @"Non-Authoritative Information";
        case 204: return @"No Content";
        case 205: return @"Reset Content";
        case 206: return @"Partial Content";
            
        case 300: return @"Multiple Choices";
        case 301: return @"Moved Permanently";
        case 302: return @"Found";
        case 303: return @"See Other";
        case 304: return @"Not Modified";
        case 305: return @"Use Proxy";
        case 306: return @"(Unused)";
        case 307: return @"Temporary Redirect";
            
        case 400: return @"Bad Request";
        case 401: return @"Unauthorized";
        case 402: return @"Payment Required";
        case 403: return @"Forbidden";
        case 404: return @"Not Found";
        case 405: return @"Method Not Allowed";
        case 406: return @"Not Acceptable";
        case 407: return @"Proxy Authentication Required";
        case 408: return @"Request Timeout";
        case 409: return @"Conflict";
        case 410: return @"Gone";
        case 411: return @"Length Required";
        case 412: return @"Precondition Failed";
        case 413: return @"Request Entity Too Large";
        case 414: return @"Request-URI Too Long";
        case 415: return @"Unsupported Media Type";
        case 416: return @"Requested Range Not Satisfiable";
        case 417: return @"Expectation Failed";
            
        case 500: return @"Internal Server Error";
        case 501: return @"Not Implemented";
        case 502: return @"Bad Gateway";
        case 503: return @"Service Unavailable";
        case 504: return @"Gateway Timeout";
        case 505: return @"HTTP Version Not Supported";
            
        default: return @"Unkown";
    }
}

@end
