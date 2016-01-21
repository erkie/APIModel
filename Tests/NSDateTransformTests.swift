//
//  NSDateTransformTests.swift
//  ApiModel
//
//  Created by Erik Rothoff Andersson on 2016-05-01.
//
//

import XCTest
import ApiModel

class NSDateTransformTests: XCTestCase {
    
    let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
    let utcTimeZone = NSTimeZone(name: "Etc/UTC")!
    let yyyyMMDDDateFormatter = NSDateFormatter()
    
    override func setUp() {
        calendar.timeZone = utcTimeZone
        yyyyMMDDDateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    func testISO8601WithoutTimezone() {
        let transform = NSDateTransform()
        let res = transform.perform("2015-12-30T12:12:33.000Z") as? NSDate
        
        let referenceDateCreator = NSDateComponents()
        referenceDateCreator.year = 2015
        referenceDateCreator.month = 12
        referenceDateCreator.day = 30
        referenceDateCreator.hour = 12
        referenceDateCreator.minute = 12
        referenceDateCreator.second = 33
        
        let referenceDate = calendar.dateFromComponents(referenceDateCreator)
        
        XCTAssertEqualWithAccuracy(res!.timeIntervalSinceReferenceDate, referenceDate!.timeIntervalSinceReferenceDate, accuracy: 0.001)
    }
    
    func testISO8601WithTimezone() {
        let transform = NSDateTransform()
        let res = transform.perform("2015-12-30T12:12:33.000-05:00") as? NSDate
        
        let referenceDateCreator = NSDateComponents()
        referenceDateCreator.year = 2015
        referenceDateCreator.month = 12
        referenceDateCreator.day = 30
        referenceDateCreator.hour = 12 + 5 // UTC is + 5 hours
        referenceDateCreator.minute = 12
        referenceDateCreator.second = 33
        
        let referenceDate = calendar.dateFromComponents(referenceDateCreator)
        
        XCTAssertEqualWithAccuracy(res!.timeIntervalSinceReferenceDate, referenceDate!.timeIntervalSinceReferenceDate, accuracy: 0.001)
    }
    
    func testUserDefinedDateFormat() {
        let now = NSDate()
        
        let transform = NSDateTransform(dateFormat: "yyyy-MM-dd")
        let res = transform.perform(now) as? NSDate
    
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Day , .Month , .Year], fromDate: now)
        
        let referenceDateCreator = NSDateComponents()
        referenceDateCreator.year = components.year
        referenceDateCreator.month = components.month
        referenceDateCreator.day = components.day
        
        let referenceDate = calendar.dateFromComponents(referenceDateCreator)
        
        XCTAssertEqual(yyyyMMDDDateFormatter.stringFromDate(res!), yyyyMMDDDateFormatter.stringFromDate(referenceDate!))
    }
    
    
    func testInvalidDate() {
        let transform = NSDateTransform()
        let res = transform.perform("i am not a date") as? NSDate
        XCTAssertNil(res)
    }
}
