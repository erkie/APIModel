//
//  ApiResponseTests.swift
//  ApiModel
//
//  Created by Craig Heneveld on 1/14/16.
//
//

import XCTest
import ApiModel
import Alamofire
import OHHTTPStubs
import RealmSwift

class ApiManagerResponseTests: XCTestCase {
    var timeout: NSTimeInterval = 10
    var testRealm: Realm!
    var host = "http://you-dont-party.com"
    
    override func setUp() {
        
        super.setUp()
        
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
        
        testRealm = try! Realm()
        
        ApiSingleton.setInstance(ApiManager(config: ApiConfig(host: self.host)))
    }
    
    override func tearDown() {
        
        super.tearDown()
        
        try! testRealm.write {
            self.testRealm.deleteAll()
        }
        
        OHHTTPStubs.removeAllStubs()
    }
    
    func testNotFoundResponse() {
        
        var theResponse: ApiModelResponse<Post>?
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            return OHHTTPStubsResponse(data:"File not found".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 404, headers: nil)
        }
        
        Api<Post>.get("/v1/posts.json") { response in
            
            XCTAssertEqual(response.rawResponse!.status!, 404, "A response should have a status of 404")
            XCTAssertTrue(response.rawResponse!.isClientError, "A response status of 404 should be invalid")
            
            theResponse = response
            
            readyExpectation.fulfill()
            OHHTTPStubs.removeAllStubs()
        }
        
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNotNil(theResponse, "Received data should not be nil")
        }
    }
    
    func testServerErrorResponse() {
        
        var theResponse: ApiModelResponse<Post>?
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            return OHHTTPStubsResponse(data:"Something went wrong!".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 500, headers: nil)
        }

        Api<Post>.get("/v1/posts.json") { response in
            
            XCTAssertEqual(response.rawResponse!.status!, 500, "A response should have a status of 500")
            XCTAssertTrue(response.rawResponse!.isInternalServerError, "A response status of 500 should be invalid")
            
            theResponse = response
            
            readyExpectation.fulfill()
            OHHTTPStubs.removeAllStubs()
        }
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNotNil(theResponse, "Received data should not be nil")
        }
    }
    
    func testSessionConfig() {
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 1 // seconds
        configuration.timeoutIntervalForResource = 1
        
        ApiSingleton.setInstance(ApiManager(config: ApiConfig(host: self.host, urlSessionConfig:configuration)))

        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            return OHHTTPStubsResponse(data:"Something went wrong!".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 500, headers: nil)
                .requestTime(2.0, responseTime: 2.0)
        }
        
        Api<Post>.get("/v1/posts.json") { response in
            
            // -1001 indicates a timeout occured which is what's expected
            XCTAssertEqual(response.error?.code, -1001)
            
            readyExpectation.fulfill()
            OHHTTPStubs.removeAllStubs()
        }
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNil(err, "Timeout occured")
        }
    }
}
