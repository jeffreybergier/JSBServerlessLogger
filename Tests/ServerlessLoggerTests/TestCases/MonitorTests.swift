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
        // configure the monitor's API stub
        self.monitor.apiClient = self.api
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        self.api.sendPayload = nil
    }

    /// Verify side-effects of presentedItemURL don't change
    func test_retryItemsPopulatedAtInit() {
        let wait1 = self.newWait(count: 2)
        var count = 0
        let outputURL = self.mock.onDisk.first!.url
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { url, _, _ in
            wait1 {
                let inboxURL = self.mock.configuration.storageLocation.inboxURL
                let outboxURL = self.mock.configuration.storageLocation.outboxURL
                switch count {
                case 0:
                    XCTAssertEqual(url, inboxURL)
                case 1:
                    XCTAssertEqual(url, outboxURL)
                default:
                    XCTFail()
                }
                count += 1
            }
            return [outputURL]
        }
        // prevent the timer from firing for the test
        self.monitor.retryTimer.invalidate()
        // this triggers the everything to be populated
        _  = self.monitor.presentedItemURL
        self.do(after: .short) {
            XCTAssertEqual(self.monitor.retryStore, [outputURL, outputURL])
        }
        self.wait(for: .medium)
    }

    func test_presentedItemURL() {
        let wait1 = self.newWait(count: 2)
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { _, _, _ in
            wait1(nil)
            return []
        }
        XCTAssertEqual(self.monitor.presentedItemURL!,
                       self.mock.configuration.storageLocation.inboxURL)
        self.wait(for: .short)
    }

    func test_presentedSubitemDidChange_success() {
        let presentedItem = self.mock.onDisk.first!.url
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait1(nil)
            return NSNumber(integerLiteral: self.mock.configuration.fileName.sizeLimit)
        }
        let wait2 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait2 {
                XCTAssertEqual(presentedItem, from)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
                XCTAssertEqual(from.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
            }
        }
        let wait3 = self.newWait()
        self.api.sendPayload = { to in
            wait3 {
                let from = presentedItem
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
                XCTAssertEqual(to.deletingLastPathComponent(), self.mock.configuration.storageLocation.outboxURL)
            }
        }
        let wait4 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait4(nil)
            try accessor(from, to)
        }
        self.monitor.presentedSubitemDidChange(at: presentedItem)
        self.wait(for: .short)
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
        let wait3 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait3(nil)
            return NSNumber(integerLiteral: self.mock.configuration.fileName.sizeLimit)
        }
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didSend(payload: payload)
        self.wait(for: .short)
    }

    func test_logic_didFailToSend_success() {
        let wait3 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait3(nil)
            return NSNumber(integerLiteral: self.mock.configuration.fileName.sizeLimit)
        }
        XCTAssertTrue(self.monitor.retryStore.isEmpty)
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        self.monitor.didFailToSend(payload: payload)
        
        self.do(after: .medium) {
            XCTAssertEqual(self.monitor.retryStore, [payload])
        }

        self.wait(for: .long)
    }

    func test_logic_presentedSubitemDidChange_failure() {
        let presentedItem = self.mock.onDisk.first!.url
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait1(nil)
            return NSNumber(integerLiteral: self.mock.configuration.fileName.sizeLimit)
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
        self.monitor.presentedSubitemDidChange(at: presentedItem)
        self.wait(for: .short)
    }

    func test_logic_didSend_failure() {
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait1(nil)
            return NSNumber(integerLiteral: self.mock.configuration.fileName.sizeLimit)
        }
        let wait2 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2(nil)
            try accessor(from, to)
        }
        let wait3 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait3(nil)
            throw NSError(domain: "TestDomain", code: -4444, userInfo: nil)
        }
        let wait4 = self.newWait()
        self.errorDelegate.error = { error, _ in
            wait4 {
                XCTAssertTrue(error.isKind(of: .moveToSent(NSError())))
            }
        }
        self.monitor.didSend(payload: payload)
        self.wait(for: .short)
    }

    func test_logic_didFailToSend_failure() {
        let payload = self.mock.configuration.storageLocation.outboxURL
                          .appendingPathComponent(self.mock.onDisk.first!.url.lastPathComponent)
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait1(nil)
            return NSNumber(integerLiteral: self.mock.configuration.fileName.sizeLimit + 1)
        }
        let wait2 = self.newWait()
        self.errorDelegate.error = { error, config in
            wait2 {
                XCTAssertTrue(error.isKind(of: .fileSize(payload)))
            }
        }
        XCTAssertTrue(self.monitor.retryStore.isEmpty)
        self.monitor.didFailToSend(payload: payload)
        self.do(after: .short) {
            XCTAssertTrue(self.monitor.retryStore.isEmpty)
        }
        self.wait(for: .medium)
    }

    func test_retry_inbox() {
        self.monitor.retryTimer.invalidate()
        let sourceURL = self.mock.onDisk.first!.url
        self.monitor.retryStore = [sourceURL]

        let wait1 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait1(nil)
            return NSNumber(value: self.mock.configuration.fileName.sizeLimit)
        }
        let wait2 = self.newWait()
        self.coor.coordinateMovingFromURLToURLByAccessor = { from, to, accessor in
            wait2(nil)
            try accessor(from, to)
        }
        let wait3 = self.newWait()
        self.fm.moveItemAtURLtoURL = { from, to in
            wait3 {
                XCTAssertEqual(to.deletingLastPathComponent(),
                               self.mock.configuration.storageLocation.outboxURL)
                XCTAssertEqual(from.lastPathComponent, to.lastPathComponent)
            }
        }
        let wait4 = self.newWait()
        self.api.sendPayload = { destURL in
            wait4 {
                XCTAssertEqual(destURL.deletingLastPathComponent(),
                               self.mock.configuration.storageLocation.outboxURL)
                XCTAssertEqual(sourceURL.lastPathComponent, destURL.lastPathComponent)
            }
        }

        self.monitor.retryTimerFired(self.monitor.retryTimer)
        self.do(after: .short) {
            XCTAssertTrue(self.monitor.retryStore.isEmpty)
        }
        self.wait(for: .medium)
    }

    func test_retry_outbox() {
        self.monitor.retryTimer.invalidate()
        let sourceURL = self.mock.configuration.storageLocation.outboxURL.appendingPathComponent(
            self.mock.onDisk.first!.url.lastPathComponent
        )
        self.monitor.retryStore = [sourceURL]

        let wait1 = self.newWait()
        self.fm.sizeOfURL = { _ in
            wait1(nil)
            return NSNumber(value: self.mock.configuration.fileName.sizeLimit)
        }
        let wait2 = self.newWait()
        self.api.sendPayload = { destURL in
            wait2 {
                XCTAssertEqual(destURL.deletingLastPathComponent(),
                               self.mock.configuration.storageLocation.outboxURL)
                XCTAssertEqual(sourceURL.lastPathComponent, destURL.lastPathComponent)
            }
        }

        self.monitor.retryTimerFired(self.monitor.retryTimer)
        self.do(after: .short) {
            XCTAssertTrue(self.monitor.retryStore.isEmpty)
        }
        self.wait(for: .medium)
    }

    func test_preflight_error_location_1() {
        let me = type(of: self.monitor)
        let url = URL(string: "file:///one/two/three/four")!
        let result = me.preflight(url: url, configuration: self.mock.configuration)
        switch result {
        case .success: XCTFail()
        case .failure(let error): XCTAssertTrue(error.isKind(of: .location(url)))
        }
    }

    func test_preflight_error_location_2() {
        let me = type(of: self.monitor)
        let url = URL(string: "file:///my/beginning/url")!
            .appendingPathComponent(self.mock.configuration.storageLocation.inboxURL.lastPathComponents(2))
            .appendingPathComponent("aFileName.txt")

        let result = me.preflight(url: url, configuration: self.mock.configuration)
        switch result {
        case .success: XCTFail()
        case .failure(let error): XCTAssertTrue(error.isKind(of: .location(url)))
        }
    }

    func test_preflight_error_extension() {
        let me = type(of: self.monitor)
        let url = URL(string: "file:///my/beginning/url")!
            .appendingPathComponent(self.mock.configuration.storageLocation.inboxURL.lastPathComponents(3))
            .appendingPathComponent("aFileName.txt")

        let result = me.preflight(url: url, configuration: self.mock.configuration)
        switch result {
        case .success: XCTFail()
        case .failure(let error): XCTAssertTrue(error.isKind(of: .fileExtension(url)))
        }
    }

    func test_preflight_error_noFile() {
        let me = type(of: self.monitor)
        let url = URL(string: "file:///my/beginning/url")!
            .appendingPathComponent(self.mock.configuration.storageLocation.inboxURL.lastPathComponents(3))
            .appendingPathComponent("aFileName.json")
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { testURL in
            wait1 {
                XCTAssertEqual(url, testURL)
            }
            throw NSError(domain: "TestDomain", code: -4444, userInfo: nil)
        }
        let result = me.preflight(url: url, configuration: self.mock.configuration)
        switch result {
        case .success: XCTFail()
        case .failure(let error): XCTAssertTrue(error.isKind(of: .fileNotPresent(url)))
        }
        self.wait(for: .instant)
    }

    func test_preflight_error_size() {
        let me = type(of: self.monitor)
        let url = URL(string: "file:///my/beginning/url")!
            .appendingPathComponent(self.mock.configuration.storageLocation.inboxURL.lastPathComponents(3))
            .appendingPathComponent("aFileName.json")
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { testURL in
            wait1 {
                XCTAssertEqual(url, testURL)
            }
            return .init(value: self.mock.configuration.fileName.sizeLimit + 1)
        }
        let result = me.preflight(url: url, configuration: self.mock.configuration)
        switch result {
        case .success: XCTFail()
        case .failure(let error): XCTAssertTrue(error.isKind(of: .fileSize(url)))
        }
        self.wait(for: .instant)
    }

    func test_preflight_success_inbox() {
        let me = type(of: self.monitor)
        let url = URL(string: "file:///my/beginning/url")!
            .appendingPathComponent(self.mock.configuration.storageLocation.inboxURL.lastPathComponents(3))
            .appendingPathComponent("aFileName.json")
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { testURL in
            wait1 {
                XCTAssertEqual(url, testURL)
            }
            return .init(value: self.mock.configuration.fileName.sizeLimit)
        }
        let result = me.preflight(url: url, configuration: self.mock.configuration)
        switch result {
        case .success: break
        case .failure: XCTFail()
        }
        self.wait(for: .instant)
    }

    func test_preflight_success_outbox() {
        let me = type(of: self.monitor)
        let url = URL(string: "file:///my/beginning/url")!
            .appendingPathComponent(self.mock.configuration.storageLocation.outboxURL.lastPathComponents(3))
            .appendingPathComponent("aFileName.json")
        let wait1 = self.newWait()
        self.fm.sizeOfURL = { testURL in
            wait1 {
                XCTAssertEqual(url, testURL)
            }
            return .init(value: self.mock.configuration.fileName.sizeLimit)
        }
        let result = me.preflight(url: url, configuration: self.mock.configuration)
        switch result {
        case .success: break
        case .failure: XCTFail()
        }
        self.wait(for: .instant)
    }
}
