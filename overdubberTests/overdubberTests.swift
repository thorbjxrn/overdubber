//
//  overdubberTests.swift
//  overdubberTests
//
//  Created by THORBJOERN THRONDSEN BONVIK on 25/5/19.
//  Copyright © 2019 THORBJOERN THRONDSEN BONVIK. All rights reserved.
//

import XCTest
@testable import overdubber

class overdubberTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMerge(){
        let stringPath = Bundle.main.url(forResource: "mp3", withExtension: "m4a")!
        let stringPath2 = Bundle.main.url(forResource: "example", withExtension: "m4a")!
        
        let C = Controller.init()
        XCTAssertTrue(C.merge(audio1: stringPath, audio2: stringPath2))
        
        
    }
    
    func testMergeRecordings(){
        //OBS THESE FILES MUST BE MADE IN RECORDER. CLEARS AT RECORDER OPEN
        let stringPath = Model.shared.getRecordingFolder().appendingPathComponent("dub0.m4a")
        let stringPath2 = Model.shared.getRecordingFolder().appendingPathComponent("dub1.m4a")
        let stringPath3 = Model.shared.getRecordingFolder().appendingPathComponent("dub2.m4a")
        let project = Model.shared.getRecordingFolder().appendingPathComponent("project.m4a")
        
        let C = Controller.init()
        XCTAssertTrue(C.merge(audio1: stringPath, audio2: stringPath2, filePath: Model.shared.getLibraryFolder().appendingPathComponent("dubMerge.m4a")))
    }
    
    func testModelInit(){
        Model.init()
        
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
