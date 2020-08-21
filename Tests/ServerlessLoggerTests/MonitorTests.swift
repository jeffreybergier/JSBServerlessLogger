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

class MonitorTests: XCTestCase {

    private let mock = Mock1.self

    let fm = FileManagerClosureStub()
    lazy var api = APIClientClosureStub(configuration: self.mock.configuration, clientDelegate: nil)
    lazy var monitor = Logger.Monitor(configuration: self.mock.configuration)

    override func setUpWithError() throws {
        try super.setUpWithError()
        ServerlessLogger.FileManager.default = self.fm
        self.monitor.apiClient = self.api
    }

    func test_presentedItemURL() {
        XCTAssertEqual(self.monitor.presentedItemURL!,
                       self.mock.configuration.storageLocation.inboxURL)
    }

    func test_logic_presentedItemDidChange() {
        let wait1 = XCTestExpectation(description: "contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions")
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { url, _, _ in
            wait1.fulfill()
            return self.mock.onDisk.map { $0.url }
        }
        let wait2 = XCTestExpectation(description: "moveItemAtURLtoURL")
        self.fm.moveItemAtURLtoURL = { from, to in
            wait2.fulfill()
            XCTAssertEqual(self.mock.onDisk.first!.url, from)
            XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
            XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
            XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
        }
        let wait3 = XCTestExpectation(description: "sendPayload")
        self.api.sendPayload = { to in
            wait3.fulfill()
            let from = self.mock.onDisk.first!.url
            XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
            XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
        }
        self.monitor.presentedItemDidChange()
        self.wait(for: [wait1, wait2, wait3], timeout: 0)
    }
}
