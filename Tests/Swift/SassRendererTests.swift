//
//  SassRendererTests.swift
//  Sass-Swift
//
//  Created by Benjamin on 16/04/2019.
//

import XCTest
import Sass

class SassRendererTests: XCTestCase {
    func testBasic() throws {
        let renderer = SassRenderer()
        
        let input = "body { a { background-color: red; } }"
        let expectation = """
        body a {
          background-color: red;
        }

        """
            
        let result = try renderer.compile(input)
            
        XCTAssertEqual(result, expectation)
    }
    
    static let allTests = [
        ("testBasic", testBasic),
    ]
}
