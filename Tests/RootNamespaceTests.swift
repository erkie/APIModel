//
//  RootNamespaceTests.swift
//  ApiModelTests
//
//  Created by Erik Rothoff Andersson on 2015-13-08.
//
//

import UIKit
import XCTest

class RootNamespaceTests: XCTestCase {
    let nestedObject = [
        "foo": [
            "bar": [
                "baz": [
                    "bam": 42
                ]
            ]
        ]
    ]
    
    let notNested = ["foo": 43]
    let singleNesting = ["foo": ["bar": 44]]
    
    let nestedButNotDictionary = [
        "foo": [
            "bar": [1, 2, 3]
        ]
    ]
    
    func testPathFormat() {
        XCTAssertNil(fetchPathFromDictionary("", dictionary: nestedObject))
        XCTAssertNil(fetchPathFromDictionary(".....................", dictionary: nestedObject))
    }
    
    func testThatItCanFetchSingleKeys() {
        XCTAssert((fetchPathFromDictionary("foo", dictionary: notNested) as? Int) == 43, "Should be able to fetch single keys")
        XCTAssertNil(fetchPathFromDictionary("not_exists", dictionary: notNested), "Should not crash if it doesn't exist")
        XCTAssertNil(fetchPathFromDictionary("not_exists.foo.bam", dictionary: notNested), "Should not crash if it doesn't exist nested")
    }
    
    func testThatItCanFetchNestingKeys() {
        XCTAssert((fetchPathFromDictionary("foo.bar.baz.bam", dictionary: nestedObject) as? Int) == 42, "Should be able to fetch single keys")
        XCTAssertNil(fetchPathFromDictionary("foo.bar.BAM", dictionary: nestedObject), "Should be able to handle non-existing keys")
    }
    
    func testThatItHandlesWrongTypes() {
        XCTAssertNil(fetchPathFromDictionary("foo.bar.bam", dictionary: nestedButNotDictionary), "Should handle bad keys")
    }
    
    func testThatItCanFetchSingleNesting() {
        if let nested = fetchPathFromDictionary("foo", dictionary: singleNesting) as? [String:Int] {
            XCTAssert(nested == ["bar": 44], "Can fetch nested objects")
        } else {
            XCTAssert(false, "Can fetch nested objects")
        }
        
        XCTAssert((fetchPathFromDictionary("foo.bar", dictionary: singleNesting) as? Int) == 44, "Can fetch singly nested objects")
    }
}
