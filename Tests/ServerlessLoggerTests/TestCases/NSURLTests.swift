//
//  Created by Jeffrey Bergier on 2020/09/05.
//
//  MIT License
//
//  Copyright (c) 2020 Jeffrey Bergier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//

import XCTest
@testable import ServerlessLogger

class NSURLTests: XCTestCase {

    func test_1_lastPathComponents() {
        let input = URL(string: "file:///Users/aname/Library/Application%20Support/An%20App/aFile.txt")!
        XCTAssertEqual(input.lastPathComponents(1), "aFile.txt")
        XCTAssertEqual(input.lastPathComponents(2), "An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(3), "Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(4), "Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(5), "aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(6), "Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(7), "//Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(8), "..///Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(9), "../..///Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(10), "../../..///Users/aname/Library/Application Support/An App/aFile.txt")
    }

    func test_2_lastPathComponents() {
        let input = URL(string: "file:///Users/aname/Library/Application%20Support/An%20App/aFile.txt/")!
        XCTAssertEqual(input.lastPathComponents(1), "aFile.txt")
        XCTAssertEqual(input.lastPathComponents(2), "An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(3), "Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(4), "Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(5), "aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(6), "Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(7), "//Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(8), "..///Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(9), "../..///Users/aname/Library/Application Support/An App/aFile.txt")
        XCTAssertEqual(input.lastPathComponents(10), "../../..///Users/aname/Library/Application Support/An App/aFile.txt")
    }

}
