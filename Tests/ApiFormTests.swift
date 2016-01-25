//
//  ApiFormTests.swift
//  APIModel
//
//  Created by Craig Heneveld on 1/14/16.
//
//

import XCTest
import ApiModel
import Alamofire
import OHHTTPStubs
import RealmSwift

class ApiFormTests: XCTestCase {
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
    
    func testSimpleFindArray() {
        
        var theResponse: [Post]?
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            let stubPath = OHPathForFile("posts.json", self.dynamicType)
            return fixture(stubPath!, headers: ["Content-Type":"application/json"])
        }
        
        Api<Post>.findArray { response, apiModelResponse in
            theResponse = response
            
            if let response = response {
                XCTAssertEqual(response.count, 2)
                XCTAssertEqual(response.first!.id, "1")
                XCTAssertEqual(response.last!.id, "2")
            }
            
            
            readyExpectation.fulfill()
            OHHTTPStubs.removeAllStubs()
        }
        
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNotNil(theResponse, "Received data should not be nil")
        }
    }
    
    func testGetWithServerFailure() {
        
        var theResponse: ApiModelResponse<Post>?
        let readyExpectation = self.expectationWithDescription("ready")
        
        
        stub({_ in true}) { request in
            let stubPath = OHPathForFile("500_error.json", self.dynamicType)
            return fixture(stubPath!, status: 500, headers: ["Content-Type":"application/json"])
        }
        
        Api<Post>.get("/v1/posts.json") { response in
            theResponse = response
            
            XCTAssertNotNil(response.serverErrors, "Response errors should not be nil")
            
            if let errors = response.serverErrors as? [[String: String]]{
                let expected: [[String: String]] = [["status":"500","code":"ServerError","detail":"A fatal error has occured."]]
                
                XCTAssertEqual(errors, expected)
                
                readyExpectation.fulfill()
                OHHTTPStubs.removeAllStubs()
            }
        }

        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNotNil(theResponse, "Received data should not be nil")
            OHHTTPStubs.removeAllStubs()
        }
    }
    
    func testFindArrayWithServerFailure() {
        
        let readyExpectation = self.expectationWithDescription("ready")
        
        
        stub({_ in true}) { request in
            return OHHTTPStubsResponse(data:"Something went wrong!".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 500, headers: nil)
        }
        
        Api<Post>.findArray { array, apiModelResponse in
            XCTAssertNil(array)
            
            if let response = array {
                XCTAssertEqual(response.count, 0)
            }
            
            XCTAssertNotNil(apiModelResponse)
            
            if let apiModelResponse = apiModelResponse {
                XCTAssertTrue(apiModelResponse.hasErrors)
                XCTAssertTrue(apiModelResponse.hasInternalServerError)
                XCTAssertFalse(apiModelResponse.hasValidationErrors)
                
                // But what happened? - the server returned meaningful validations but are lost!
                XCTAssertNotNil(apiModelResponse.serverErrorMessages)
                
                if let errorMessages = apiModelResponse.serverErrorMessages {
                    XCTAssertEqual(errorMessages, ["Base: An unexpected server error occured"])
                }

            }
            
            readyExpectation.fulfill()
            OHHTTPStubs.removeAllStubs()
        }

        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNil(err, "Timeout occured")
        }
    }
    
    func testFindWithServerFailure() {
        
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            let stubPath = OHPathForFile("500_error.json", self.dynamicType)
            return fixture(stubPath!, status: 500, headers: ["Content-Type":"application/json"])
        }
        
        Api<Post>.find { response, apiModelResponse in

            XCTAssertNil(response)
            
            readyExpectation.fulfill()
            OHHTTPStubs.removeAllStubs()
        }
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNil(err, "Received data should be nil")
        }
    }
    
    func testSaveWithModelValidationErrors() {
        
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            let stubPath = OHPathForFile("post_with_error.json", self.dynamicType)
            return fixture(stubPath!, status: 422, headers: ["Content-Type":"application/json"])
        }
        
        let post = Post()

        let form = Api<Post>(model: post)
        
        form.save { apiModelResponse in
            XCTAssertTrue(apiModelResponse.hasErrors)
            XCTAssertFalse(apiModelResponse.hasInternalServerError)
            XCTAssertTrue(apiModelResponse.hasValidationErrors)
            
            XCTAssertNotNil(apiModelResponse.validationErrors)
            
            // But what happened? - the server returned meaningful validations but are lost!
            if let validationErrors = apiModelResponse.validationErrorMessages {
                XCTAssertEqual(validationErrors, ["Title: must not be blank!", "Contents: must not be blank!"])
            }
            

            readyExpectation.fulfill()
            
            OHHTTPStubs.removeAllStubs()
        }
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNil(err, "Received data should be nil")
        }
    }
    
    func testSaveWithServerErrors() {
        
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            let stubPath = OHPathForFile("500_error.json", self.dynamicType)
            return fixture(stubPath!, status: 500, headers: ["Content-Type":"application/json"])
        }
        
        let post = Post()
        
        let form = Api<Post>(model: post)
        
        form.save { apiModelResponse in
            XCTAssertTrue(apiModelResponse.hasErrors)
            XCTAssertTrue(apiModelResponse.hasInternalServerError)
            XCTAssertFalse(apiModelResponse.hasValidationErrors)
            
            XCTAssertNotNil(apiModelResponse.serverErrorMessages)
            
            if let errorMessages = apiModelResponse.serverErrorMessages {
                XCTAssertEqual(errorMessages, ["Status: 500","Detail: A fatal error has occured.","Code: ServerError"])
            }

            
            readyExpectation.fulfill()
            
            OHHTTPStubs.removeAllStubs()
        }
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNil(err, "Received data should be nil")
        }
    }
    
    func testSaveWithHTMLServerErrors() {
        
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            return OHHTTPStubsResponse(data:"<body>Something went wrong!</body>".dataUsingEncoding(NSUTF8StringEncoding)!, statusCode: 500, headers: nil)
        }
        
        let post = Post()
        
        let form = Api<Post>(model: post)
        
        form.save { apiModelResponse in
            XCTAssertTrue(apiModelResponse.hasErrors)
            XCTAssertTrue(apiModelResponse.hasInternalServerError)
            XCTAssertFalse(apiModelResponse.hasValidationErrors)
            
            // But what happened? - the server returned meaningful validations but are lost!
            XCTAssertNotNil(apiModelResponse.serverErrorMessages)
            
            if let errorMessages = apiModelResponse.serverErrorMessages {
                XCTAssertEqual(errorMessages, ["Base: An unexpected server error occured"])
            }
            
            readyExpectation.fulfill()
            
            OHHTTPStubs.removeAllStubs()
        }
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNil(err, "Received data should be nil")
        }
    }
    
    func testStoreObjectWithErrorsFromApiThatAlreadyExists() {
        let author = Author()
        author.id = "1"
        author.name = "Babaji"
        
        let post = Post()
        post.id = "1"
        post.title = "My Title"
        post.contents = "My Contents"
        post.createdAt = NSDate()
        post.author = author
        
        try! testRealm.write {
            self.testRealm.add(post)
        }
        
        let readyExpectation = self.expectationWithDescription("ready")
        
        stub({_ in true}) { request in
            let stubPath = OHPathForFile("post_with_attributes_and_error.json", self.dynamicType)
            return fixture(stubPath!, status: 422, headers: ["Content-Type":"application/json"])
        }
        
        let form = Api<Post>(model: post)
        
        form.save { apiModelResponse in
            XCTAssertTrue(apiModelResponse.hasErrors)
            XCTAssertFalse(apiModelResponse.hasInternalServerError)
            XCTAssertTrue(apiModelResponse.hasValidationErrors)

            XCTAssertEqual(apiModelResponse.object!.id, "1")
            XCTAssertEqual(apiModelResponse.object!.title, "My Test")
            XCTAssertEqual(apiModelResponse.object!.contents, "My Contents")
            
            readyExpectation.fulfill()
            
            OHHTTPStubs.removeAllStubs()
        }
        
        self.waitForExpectationsWithTimeout(self.timeout) { err in
            // By the time we reach this code, the while loop has exited
            // so the response has arrived or the test has timed out
            XCTAssertNil(err, "Received data should be nil")
        }
        
    }
}
