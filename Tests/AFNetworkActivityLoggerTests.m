//
//  AFNetworkActivityLoggerTests.m
//  AFNetworkActivityLoggerTests
//
//  Created by Kevin Harwood on 12/14/15.
//  Copyright © 2015 Alamofire. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AFNetworkActivityLogger/AFNetworkActivityLogger.h>
#import <AFNetworkActivityLogger/AFNetworkActivityConsoleLogger.h>
#import <AFNetworking/AFNetworking.h>

@interface AFNetworkActivityTestLogger : NSObject <AFNetworkActivityLoggerProtocol>

@property (nonatomic, strong) NSPredicate *filterPredicate;
@property (nonatomic, assign) AFHTTPRequestLoggerLevel level;

@property (nonatomic, copy) void (^startBlock)(NSURLSessionTask *);
@property (nonatomic, copy) void (^finishBlock)(NSURLSessionTask *, id, NSTimeInterval, NSError *);

@end

@implementation AFNetworkActivityTestLogger

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


@interface AFNetworkActivityLoggerTests : XCTestCase
@property (nonatomic, strong) AFNetworkActivityLogger *logger;
@end

@implementation AFNetworkActivityLoggerTests

- (void)setUp {
    [super setUp];
    self.logger = [AFNetworkActivityLogger new];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self.logger stopLogging];
    [super tearDown];
}

- (void)testSharedLoggerIsNotEqualToInitedLogger {
    XCTAssertFalse([self.logger isEqual:[AFNetworkActivityLogger sharedLogger]]);
}

- (void)testInitialStateIsProperlyConfigured {
    XCTAssertTrue(self.logger.loggers.count == 1);
    NSArray *array = [self.logger.loggers allObjects];
    id <AFNetworkActivityLoggerProtocol> consoleLogger = [array objectAtIndex:0];
    XCTAssertTrue([consoleLogger isKindOfClass:[AFNetworkActivityConsoleLogger class]]);
    XCTAssertTrue(consoleLogger.level == AFLoggerLevelInfo);
}

- (void)testLoggerCanBeAdded {
    NSUInteger initialCount = self.logger.loggers.count;

    AFNetworkActivityConsoleLogger *newLogger = [AFNetworkActivityConsoleLogger new];
    [self.logger addLogger:newLogger];
    XCTAssertTrue(self.logger.loggers.count == initialCount + 1);
}

- (void)testLoggerCanBeRemoved {
    AFNetworkActivityConsoleLogger *newLogger = [AFNetworkActivityConsoleLogger new];
    [self.logger addLogger:newLogger];

    NSUInteger count = self.logger.loggers.count;

    [self.logger removeLogger:newLogger];
    XCTAssertTrue(self.logger.loggers.count == count - 1);
}

- (void)testLogLevelCanBeSetOnAllLoggersSimultaneously {
    AFNetworkActivityConsoleLogger *firstLogger = [AFNetworkActivityConsoleLogger new];
    firstLogger.level = AFLoggerLevelInfo;
    AFNetworkActivityConsoleLogger *secondLogger = [AFNetworkActivityConsoleLogger new];
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
    AFNetworkActivityTestLogger *testLogger = [AFNetworkActivityTestLogger new];

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
    AFNetworkActivityTestLogger *testLogger = [AFNetworkActivityTestLogger new];

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
    AFNetworkActivityTestLogger *testLogger = [AFNetworkActivityTestLogger new];

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
    AFNetworkActivityTestLogger *testLogger = [AFNetworkActivityTestLogger new];


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
    AFNetworkActivityTestLogger *testLogger = [AFNetworkActivityTestLogger new];


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
    AFNetworkActivityTestLogger *testLogger = [AFNetworkActivityTestLogger new];


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


@end
