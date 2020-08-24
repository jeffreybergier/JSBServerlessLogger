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
@testable import ServerlessLogger

class MonitorTests: LoggerTestCase {

    private let mock = Mock1.self

    lazy var api = APIClientClosureStub(configuration: self.mock.configuration, clientDelegate: nil)
    lazy var monitor = Logger.Monitor(configuration: self.mock.configuration)

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Make sure stub is ready for Monitor.performOutboxCleanup
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { _, _, _ in
            return []
        }
        // configure the monitor's API stub
        self.monitor.apiClient = self.api
    }

    func test_presentedItemURL() {
        XCTAssertEqual(self.monitor.presentedItemURL!,
                       self.mock.configuration.storageLocation.inboxURL)
    }

    func test_logic_presentedItemDidChange_success() {
        let wait1 = self.newWait()
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { url, _, _ in
            wait1(nil)
            return self.mock.onDisk.map { $0.url }
        }
        let wait2 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait2 {
                XCTAssertEqual(self.mock.onDisk.first!.url, from)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
                XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
            }
        }
        let wait3 = self.newWait()
        self.api.sendPayload = { to in
            wait3 {
                let from = self.mock.onDisk.first!.url
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
            }
        }
        let wait4 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait4(nil)
            try accessor(from, to)
        }
        self.monitor.presentedItemDidChange()
        self.waitShort()
    }

    func test_logic_didSend_success() {
        let wait1 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait1 {
                // check that the file names match
                XCTAssertEqual(self.mock.onDisk.first!.url.lastPathComponent, from.lastPathComponent)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                // check that from is the outbox
                XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
                // check that to is the sent
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.sentURL)
            }
        }
        let wait2 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2(nil)
            try accessor(from, to)
        }
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didSend(payload: payload)
        self.waitShort()
    }

    func test_logic_didFailToSend_success() {
        let wait1 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait1 {
                // check that the file names match
                XCTAssertEqual(self.mock.onDisk.first!.url.lastPathComponent, from.lastPathComponent)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                // check that from is the outbox
                XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
                // check that to is the inbox
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
            }
        }
        let wait2 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2(nil)
            try accessor(from, to)
        }
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didFailToSend(payload: payload)
        self.waitShort()
    }

    func test_logic_presentedItemDidChange_failure() {
        let wait1 = self.newWait()
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { url, _, _ in
            wait1(nil)
            return self.mock.onDisk.map { $0.url }
        }
        let wait2 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait2(nil)
            throw NSError(domain: "TestDomain", code: -4444, userInfo: nil)
        }
        let wait3 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait3(nil)
            try accessor(from, to)
        }
        let wait4 = self.newWait()
        self.errorDelegate.error = { error, config in
            wait4 {
                XCTAssertTrue(error.isKind(of: .moveToOutbox(NSError())))
            }
        }
        self.monitor.presentedItemDidChange()
        self.waitShort()
    }

    func test_logic_didSend_failure() {
        let wait1 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait1(nil)
            throw NSError(domain: "TestDomain", code: -4444, userInfo: nil)
        }
        let wait2 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2(nil)
            try accessor(from, to)
        }
        let wait3 = self.newWait()
        self.errorDelegate.error = { error, config in
            wait3 {
                XCTAssertTrue(error.isKind(of: .moveToSent(NSError())))
            }
        }
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didSend(payload: payload)
        self.waitShort()
    }

    func test_logic_didFailToSend_failure() {
        let wait1 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait1(nil)
            throw NSError(domain: "TestDomain", code: -4444, userInfo: nil)
        }
        let wait2 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2(nil)
            try accessor(from, to)
        }
        let wait3 = self.newWait()
        self.errorDelegate.error = { error, config in
            wait3 {
                XCTAssertTrue(error.isKind(of: .moveToInbox(NSError())))
            }
        }
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didFailToSend(payload: payload)
        self.waitShort()
    }

    func test_outboxCleanup_success() {
        let wait1 = self.newWait()
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { url, _, _ in
            wait1 {
                XCTAssertEqual(url, self.mock.configuration.storageLocation.outboxURL)
            }
            return [self.mock.configuration.storageLocation.outboxURL.appendingPathComponent("This-Is-A-Test.file")]
        }
        let wait2 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait2 {
                XCTAssertEqual(from, self.mock.configuration.storageLocation.outboxURL.appendingPathComponent("This-Is-A-Test.file"))
                XCTAssertEqual(to, self.mock.configuration.storageLocation.inboxURL.appendingPathComponent("This-Is-A-Test.file"))
            }
        }
        let wait3 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait3 {
                XCTAssertEqual(from, self.mock.configuration.storageLocation.outboxURL.appendingPathComponent("This-Is-A-Test.file"))
                XCTAssertEqual(to, self.mock.configuration.storageLocation.inboxURL.appendingPathComponent("This-Is-A-Test.file"))
            }
            try accessor(from, to)
        }
        self.monitor.performOutboxCleanup()
        self.waitInstant()
    }

    func test_outboxCleanup_failure() {
        let wait1 = self.newWait()
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { url, _, _ in
            wait1 {
                XCTAssertEqual(url, self.mock.configuration.storageLocation.outboxURL)
            }
            return [self.mock.configuration.storageLocation.outboxURL.appendingPathComponent("This-Is-A-Test.file")]
        }
        let wait2 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait2(nil)
            throw NSError(domain: "", code: -4444, userInfo: nil)
        }
        let wait3 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait3(nil)
            try accessor(from, to)
        }
        let wait4 = self.newWait()
        self.errorDelegate.error = { error, _ in
            wait4 {
                XCTAssertTrue(error.isKind(of: .moveToInbox(NSError())))
            }
        }
        self.monitor.performOutboxCleanup()
        self.waitInstant()
    }
}
