//
//  SassRendererTests.swift
//  Sass-Swift
//
//  Created by Benjamin on 16/04/2019.
//

import XCTest
import Sass

class SassRendererTests: XCTestCase {
    func testBasic() {
        let renderer = SassRenderer()
        
        let result = renderer.compile("body { a { background-color: red; } }")
        print(result)
    }
}
