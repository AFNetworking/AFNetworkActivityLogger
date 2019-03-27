# AFNetworkingLogger

`AFNetworkingLogger` is an extension for [AFNetworking](http://github.com/AFNetworking/AFNetworking/) 3.0 that logs network requests as they are sent and received.

> `AFNetworkingLogger` listens `AFNetworkingTaskDidStartNotification` and `AFNetworkingTaskDidFinishNotification` notifications, which are posted by AFNetworking as session tasks are started and finish. For further customization of logging output, users are encouraged to implement desired functionality by creating new objects that conform to `AFNetworkingLoggerProtocol`.

## Usage
1、Add the following code to `Podfile` in your project:

```
pod 'AFNetworkingLogger', '~> 1.0.0'
```

2、Execute the following command to install this lib:

```
pod install
```

3、import `AFNetworkingLogger.h` header in `AppDelegate.m`:

``` objective-c
#import "AFNetworkingLogger.h"
```

4、Add the following code to `AppDelegate.m -application:didFinishLaunchingWithOptions:`:

``` objective-c
[[AFNetworkingLogger sharedLogger] startLogging];
```

5、Now all `NSURLSessionTask` objects created by an `AFURLSessionManager` will have their request and response logged to the console, a la:

```
--------------------------------------------------
POST /user/login HTTP/1.1
Host: https://www.wanandroid.com:80
User-Agent: iOSTest/1.0 (iPhone; iOS 12.1; Scale/3.00)
Content-Type: application/json
Accept-Language: en;q=1

{"username":"fpliu","password":"123456"}
--------------------------------------------------
https://www.wanandroid.com/user/login--->

HTTP/1.1 200
Transfer-Encoding: Identity
Content-Type: application/json;charset=UTF-8
Server: Apache-Coyote/1.1
Date: Mon, 25 Mar 2019 05:48:09 GMT

{
  "code" : 1,
  "message" : "用户名或密码错误"
}
--------------------------------------------------
```

## Filtering Requests
To limit the requests that are logged by a unique logger, each object that conforms to `AFNetworkingLoggerProtocol` has a `filterPredicate` property. If the predicate returns true, the request will not be forwarded to the logger. For example, a custom file logger could be created that only logs requests for `http://httpbin.org`, while a console logger could be used to log all errors in the application.

```Objective-C
AFNetworkingConsoleLogger *testLogger = [AFNetworkingConsoleLogger new];
NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSURLRequest *  _Nonnull request, NSDictionary<NSString *,id> * _Nullable bindings) {
    return !([[request URL] baseURL] isEqualToString:@"httpbin.org"])
}];
[testLogger setFilterPredicate:predicate];
```    

## Custom Loggers
By default, the shared logger is configured with an `AFNetworkingConsoleLogger`.

To create a custom logger, create a new object that conforms to `AFNetworkingLoggerProtocol`, and add it to the shared logger. Be sure and configure the proper default logging level.

## License

AFNetworkingLogger is available under the MIT license. See the LICENSE file for more info.
