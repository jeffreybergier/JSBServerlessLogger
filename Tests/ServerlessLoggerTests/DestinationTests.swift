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

class DestinationTests: ParentTest {

    let mock: MockProtocol.Type = Mock1.self

    lazy var dest = try! Logger.Destination<Event>.new(configuration: self.mock.configuration).get()

    override func setUpWithError() throws {
        try super.setUpWithError()
        ServerlessLogger.FileManager.default = self.fm
        ServerlessLogger.NSFileCoordinator.testReplacement = self.coor
    }

    func test_logic_isEnabledFor() {
        let wait1 = XCTestExpectation()
        wait1.expectedFulfillmentCount = 3
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1.fulfill()
            isDirectory!.pointee = true
            return true
        }
        let wait2 = XCTestExpectation()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2.fulfill()
        }
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
        self.wait(for: [wait1, wait2], timeout: 0.0)
    }

    func test_logic_init_directoriesExist() {
        let wait1 = XCTestExpectation()
        wait1.expectedFulfillmentCount = 3
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1.fulfill()
            isDirectory!.pointee = true
            return true
        }
        let wait2 = XCTestExpectation()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2.fulfill()
        }
        self.fm.createDirectoryAtURLWithIntermediateDirectoriesAttributes = { _, _, _ in
            XCTFail()
        }
        _ = self.dest
        self.wait(for: [wait1, wait2], timeout: 0.0)
    }

    func test_logic_init_directoriesDontExist() {
        let wait1 = XCTestExpectation()
        wait1.expectedFulfillmentCount = 3
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1.fulfill()
            return false
        }
        let wait2 = XCTestExpectation()
        wait2.expectedFulfillmentCount = 3
        var wait2Count = 0
        self.fm.createDirectoryAtURLWithIntermediateDirectoriesAttributes = { url, _, _ in
            switch wait2Count {
            case 0:
                XCTAssertEqual(url, self.mock.configuration.storageLocation.inboxURL)
            case 1:
                XCTAssertEqual(url, self.mock.configuration.storageLocation.outboxURL)
            case 2:
                XCTAssertEqual(url, self.mock.configuration.storageLocation.sentURL)
            default:
                XCTFail()
            }
            wait2Count += 1
            wait2.fulfill()
        }
        let wait3 = XCTestExpectation(description: "Verify this object is added as a File Presenter")
        type(of: self.coor).addFilePresenter = { input in
            wait3.fulfill()
            XCTAssertTrue(input.isKind(of: Logger.Monitor.self))
        }
        _ = self.dest
        self.wait(for: [wait1, wait2, wait3], timeout: 0.0)
    }

    func test_logic_init_error() {
        let wait1 = XCTestExpectation(description: "fileExistsAtPathIsDirectory")
        wait1.expectedFulfillmentCount = 1
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1.fulfill()
            isDirectory!.pointee = false
            return true
        }
        self.fm.createDirectoryAtURLWithIntermediateDirectoriesAttributes = { _, _, _ in
            XCTFail()
        }
        let wait2 = XCTestExpectation(description: "Logger.Destination")
        do {
            _ = try Logger.Destination<Event>(configuration: self.mock.configuration)
            XCTFail()
        } catch {
            wait2.fulfill()
            if case Logger.Error.destinationDirectorySetupError = error as! Logger.Error
            { return }
            else { XCTFail(String(describing: error)) }
        }
        self.wait(for: [wait1, wait2], timeout: 0.1)
    }

    func test_appendToInbox_success() {
        let wait1 = XCTestExpectation()
        wait1.expectedFulfillmentCount = 3
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1.fulfill()
            isDirectory!.pointee = true
            return true
        }
        let wait2 = XCTestExpectation()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2.fulfill()
        }
        let wait3 = XCTestExpectation()
        self.fm.createFileAtPathWithContentsAttributes = { path, data, _ in
            wait3.fulfill()
            let url = URL(string: path)!
            XCTAssertEqual(url.deletingLastPathComponent().path, self.mock.configuration.storageLocation.inboxURL.path)
            let event = try! JSONDecoder().decode(Event.self, from: data!)
            XCTAssertEqual(event, self.mock.event)
            return true
        }
        self.dest.appendToInbox(self.mock.event)
        self.wait(for: [wait1, wait2, wait3], timeout: 0.0)
    }

    func test_appendToInbox_error() {
        let wait1 = XCTestExpectation()
        wait1.expectedFulfillmentCount = 3
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1.fulfill()
            isDirectory!.pointee = true
            return true
        }
        let wait2 = XCTestExpectation()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2.fulfill()
        }
        let wait3 = XCTestExpectation()
        self.fm.createFileAtPathWithContentsAttributes = { _, _, _ in
            wait3.fulfill()
            return false
        }
        let wait4 = XCTestExpectation()
        self.errorDelegate.errorConfiguration = { error, _ in
            wait4.fulfill()
            if case .writeToInboxError(let url, _) = error {
                XCTAssertEqual(url.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
            } else {
                XCTFail("Wrong Error: \(error)")
            }
        }
        self.dest.appendToInbox(self.mock.event)
        self.wait(for: [wait1, wait2, wait3], timeout: 0.0)
    }
    
}
