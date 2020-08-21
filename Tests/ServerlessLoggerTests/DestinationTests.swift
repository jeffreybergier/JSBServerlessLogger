//
//  Created by Jeffrey Bergier on 2020/08/21.
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
import Foundation
@testable import ServerlessLogger

class DestinationTests: XCTestCase {

    let mock: MockProtocol.Type = Mock1.self
    lazy var dest = try! Logger.Destination<Event>(configuration: self.mock.configuration)

    func test_logic_isEnabledFor() {
        XCTAssertFalse(self.dest.isEnabledFor(level: .verbose))
        XCTAssertFalse(self.dest.isEnabledFor(level: .debug))
        XCTAssertFalse(self.dest.isEnabledFor(level: .info))
        XCTAssertFalse(self.dest.isEnabledFor(level: .notice))
        XCTAssertFalse(self.dest.isEnabledFor(level: .warning))
        XCTAssertTrue(self.dest.isEnabledFor(level: .error))
        XCTAssertTrue(self.dest.isEnabledFor(level: .severe))
        XCTAssertTrue(self.dest.isEnabledFor(level: .alert))
        XCTAssertTrue(self.dest.isEnabledFor(level: .emergency))
        XCTAssertTrue(self.dest.isEnabledFor(level: .none))
    }
    
}
