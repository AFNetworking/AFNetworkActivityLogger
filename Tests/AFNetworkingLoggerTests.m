//
//  AFNetworkingLoggerTests.m
//  AFNetworkingLoggerTests
//
//  Created by Kevin Harwood on 12/14/15.
//  Copyright © 2015 Alamofire. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AFNetworkingLogger/AFNetworkingLogger.h>
#import <AFNetworkingLogger/AFNetworkingConsoleLogger.h>
#import <AFNetworking/AFNetworking.h>

@interface AFNetworkingTestLogger : NSObject <AFNetworkingLoggerProtocol>

@property (nonatomic, strong) NSPredicate *filterPredicate;
@property (nonatomic, assign) AFHTTPRequestLoggerLevel level;

@property (nonatomic, copy) void (^startBlock)(NSURLSessionTask *);
@property (nonatomic, copy) void (^finishBlock)(NSURLSessionTask *, id, NSTimeInterval, NSError *);

@end

@implementation AFNetworkingTestLogger

- (void)URLSessionTaskDidStart:(NSURLSessionTask *)task {
    if (self.startBlock) {
        self.startBlock(task);
    }
}

- (void)URLSessionTaskDidFinish:(NSURLSessionTask *)task withResponseObject:(id)responseObject inElapsedTime:(NSTimeInterval)elapsedTime withError:(NSError *)error {
    if (self.finishBlock) {
        self.finishBlock(task, responseObject, elapsedTime, error);
    }
}

@end


@interface AFNetworkingLoggerTests : XCTestCase
@property (nonatomic, strong) AFNetworkingLogger *logger;
@end

@implementation AFNetworkingLoggerTests

- (void)setUp {
    [super setUp];
    self.logger = [AFNetworkingLogger new];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self.logger stopLogging];
    [super tearDown];
}

- (void)testSharedLoggerIsNotEqualToInitedLogger {
    XCTAssertFalse([self.logger isEqual:[AFNetworkingLogger sharedLogger]]);
}

- (void)testInitialStateIsProperlyConfigured {
    XCTAssertTrue(self.logger.loggers.count == 1);
    NSArray *array = [self.logger.loggers allObjects];
    id <AFNetworkingLoggerProtocol> consoleLogger = [array objectAtIndex:0];
    XCTAssertTrue([consoleLogger isKindOfClass:[AFNetworkingConsoleLogger class]]);
    XCTAssertTrue(consoleLogger.level == AFLoggerLevelInfo);
}

- (void)testLoggerCanBeAdded {
    NSUInteger initialCount = self.logger.loggers.count;

    AFNetworkingConsoleLogger *newLogger = [AFNetworkingConsoleLogger new];
    [self.logger addLogger:newLogger];
    XCTAssertTrue(self.logger.loggers.count == initialCount + 1);
}

- (void)testLoggerCanBeRemoved {
    AFNetworkingConsoleLogger *newLogger = [AFNetworkingConsoleLogger new];
    [self.logger addLogger:newLogger];

    NSUInteger count = self.logger.loggers.count;

    [self.logger removeLogger:newLogger];
    XCTAssertTrue(self.logger.loggers.count == count - 1);
}

- (void)testLogLevelCanBeSetOnAllLoggersSimultaneously {
    AFNetworkingConsoleLogger *firstLogger = [AFNetworkingConsoleLogger new];
    firstLogger.level = AFLoggerLevelInfo;
    AFNetworkingConsoleLogger *secondLogger = [AFNetworkingConsoleLogger new];
    secondLogger.level = AFLoggerLevelError;
    
    [self.logger addLogger:firstLogger];
    [self.logger addLogger:secondLogger];
    
    [self.logger setLogLevel:AFLoggerLevelDebug];
    
    XCTAssertTrue(firstLogger.level == AFLoggerLevelDebug);
    XCTAssertTrue(secondLogger.level == AFLoggerLevelDebug);
}

- (void)testThatStartCallbackIsReceived {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Start Block Should Be Called"];
    [testLogger setStartBlock:^(NSURLSessionTask *task) {
        XCTAssertNotNil(task);
        [expectation fulfill];
    }];
    [self.logger addLogger:testLogger];
    [self.logger startLogging];

    [manager
     GET:@"ip"
     parameters:nil
     progress:nil
     success:nil
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testThatFinishCallbackIsReceived {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Finish Block Should Be Called"];
    [testLogger setFinishBlock:^(NSURLSessionTask *task, id responseObject, NSTimeInterval elpasedTime, NSError *error) {
        XCTAssertNotNil(task);
        XCTAssertNotNil(responseObject);
        XCTAssertTrue(elpasedTime > 0);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self.logger addLogger:testLogger];
    [self.logger startLogging];

    [manager
     GET:@"ip"
     parameters:nil
     progress:nil
     success:nil
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testThatFinishCallbackIsReceivedWithError {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Finish Block Should Be Called"];
    [testLogger setFinishBlock:^(NSURLSessionTask *task, id responseObject, NSTimeInterval elpasedTime, NSError *error) {
        XCTAssertNotNil(task);
        XCTAssertNil(responseObject);
        XCTAssertTrue(elpasedTime > 0);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self.logger addLogger:testLogger];
    [self.logger startLogging];

    [manager
     GET:@"status/404"
     parameters:nil
     progress:nil
     success:nil
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testThatFilterPredicateIsRespectedForStartCallback {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];


    [testLogger setStartBlock:^(NSURLSessionTask *task) {
        XCTFail(@"Start block should not be called");
    }];

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSURLRequest *  _Nonnull request, NSDictionary<NSString *,id> * _Nullable bindings) {
        return true;
    }];
    [testLogger setFilterPredicate:predicate];

    [self.logger addLogger:testLogger];
    [self.logger startLogging];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [manager
     GET:@"ip"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testThatFilterPredicateIsRespectedForFinishCallback {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];


    [testLogger setFinishBlock:^(NSURLSessionTask *task, id responseObject, NSTimeInterval elapsedTime, NSError *error) {
        XCTFail(@"Start block should not be called");
    }];

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSURLRequest *  _Nonnull request, NSDictionary<NSString *,id> * _Nullable bindings) {
        return true;
    }];
    [testLogger setFilterPredicate:predicate];

    [self.logger addLogger:testLogger];
    [self.logger startLogging];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [manager
     GET:@"ip"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testThatIndividualLoggerIsNotCalledWhenLoggerIsNilledOut {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];


    [testLogger setStartBlock:^(NSURLSessionTask *task) {
        XCTFail(@"Start block should not be called");
    }];

    [self.logger addLogger:testLogger];
    [self.logger startLogging];
    self.logger = nil;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [manager
     GET:@"ip"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
         [expectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testThatResponseSerializerIsAFHTTPResponseSerializerAndResponseBodyIsText {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Finish Block Should Be Called"];
    [testLogger setFinishBlock:^(NSURLSessionTask *task, id responseObject, NSTimeInterval elpasedTime, NSError *error) {
        [expectation fulfill];
    }];
    [self.logger addLogger:testLogger];
    [self.logger setLogLevel:AFLoggerLevelDebug];
    [self.logger startLogging];
    
    [manager
     GET:@"ip"
     parameters:nil
     progress:nil
     success:nil
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testThatResponseSerializerIsAFHTTPResponseSerializerAndResponseBodyIsNotText {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Finish Block Should Be Called"];
    [testLogger setFinishBlock:^(NSURLSessionTask *task, id responseObject, NSTimeInterval elpasedTime, NSError *error) {
        [expectation fulfill];
    }];
    [self.logger addLogger:testLogger];
    [self.logger setLogLevel:AFLoggerLevelDebug];
    [self.logger startLogging];
    
    [manager
     GET:@"image/jpeg"
     parameters:nil
     progress:nil
     success:nil
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testYY {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Finish Block Should Be Called"];
    [testLogger setFinishBlock:^(NSURLSessionTask *task, id responseObject, NSTimeInterval elpasedTime, NSError *error) {
        [expectation fulfill];
    }];
    [self.logger addLogger:testLogger];
    [self.logger setLogLevel:AFLoggerLevelDebug];
    [self.logger startLogging];
    
    [manager
     POST:@"post"
     parameters:@"x=y"
     progress:nil
     success:nil
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

- (void)testZZ {
    NSURL *baseURL = [NSURL URLWithString:@"https://httpbin.org"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFNetworkingTestLogger *testLogger = [AFNetworkingTestLogger new];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Finish Block Should Be Called"];
    [testLogger setFinishBlock:^(NSURLSessionTask *task, id responseObject, NSTimeInterval elpasedTime, NSError *error) {
        [expectation fulfill];
    }];
    
    [self.logger addLogger:testLogger];
    [self.logger setLogLevel:AFLoggerLevelError];
    [self.logger startLogging];
    
    [manager
     POST:@"status/404"
     parameters:@"x=y"
     progress:nil
     success:nil
     failure:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    [manager invalidateSessionCancelingTasks:YES];
}

@end
