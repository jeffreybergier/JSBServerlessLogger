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

class MonitorTests: ParentTest {

    private let mock = Mock1.self

    lazy var api = APIClientClosureStub(configuration: self.mock.configuration, clientDelegate: nil)
    lazy var monitor = Logger.Monitor(configuration: self.mock.configuration)

    override func setUpWithError() throws {
        try super.setUpWithError()
        ServerlessLogger.FileManager.default = self.fm
        ServerlessLogger.NSFileCoordinator.testReplacement = self.coor
        self.monitor.apiClient = self.api
    }

    func test_presentedItemURL() {
        XCTAssertEqual(self.monitor.presentedItemURL!,
                       self.mock.configuration.storageLocation.inboxURL)
    }

    func test_logic_presentedItemDidChange() {
        let wait1 = XCTestExpectation(description: "contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions")
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { url, _, _ in
            DispatchQueue.main.async { wait1.fulfill() }
            return self.mock.onDisk.map { $0.url }
        }
        let wait2 = XCTestExpectation(description: "moveItemAtURLtoURL")
        self.fm.moveItemAtURLtoURL = { from, to in
            DispatchQueue.main.async {
                wait2.fulfill()
                XCTAssertEqual(self.mock.onDisk.first!.url, from)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
                XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
            }
        }
        let wait3 = XCTestExpectation(description: "sendPayload")
        self.api.sendPayload = { to in
            DispatchQueue.main.async {
                wait3.fulfill()
                let from = self.mock.onDisk.first!.url
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
            }
        }
        let wait4 = XCTestExpectation(description: "coordinateMovingFromURLToURLByAccessor")
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait4.fulfill()
            try accessor(from, to)
        }
        self.monitor.presentedItemDidChange()
        self.wait(for: [wait1, wait2, wait3, wait4], timeout: 0.1)
    }

    func test_logic_didSend() {
        let wait1 = XCTestExpectation(description: "moveItemAtURLtoURL")
        self.fm.moveItemAtURLtoURL = { from, to in
            DispatchQueue.main.async {
                wait1.fulfill()
                // check that the file names match
                XCTAssertEqual(self.mock.onDisk.first!.url.lastPathComponent, from.lastPathComponent)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                // check that from is the outbox
                XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
                // check that to is the sent
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.sentURL)
            }
        }
        let wait2 = XCTestExpectation(description: "coordinateMovingFromURLToURLByAccessor")
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2.fulfill()
            try accessor(from, to)
        }
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didSend(payload: payload)
        self.wait(for: [wait1, wait2], timeout: 0.1)
    }

    func test_logic_didFailToSend() {
        let wait1 = XCTestExpectation(description: "moveItemAtURLtoURL")
        self.fm.moveItemAtURLtoURL = { from, to in
            DispatchQueue.main.async {
                wait1.fulfill()
                // check that the file names match
                XCTAssertEqual(self.mock.onDisk.first!.url.lastPathComponent, from.lastPathComponent)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                // check that from is the outbox
                XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
                // check that to is the inbox
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
            }
        }
        let wait2 = XCTestExpectation(description: "coordinateMovingFromURLToURLByAccessor")
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2.fulfill()
            try accessor(from, to)
        }
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didFailToSend(payload: payload)
        self.wait(for: [wait1, wait2], timeout: 0.1)
    }
}
