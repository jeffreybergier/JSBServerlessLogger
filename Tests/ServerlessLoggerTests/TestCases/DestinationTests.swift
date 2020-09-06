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

class DestinationTests: LoggerTestCase {

    let mock: MockProtocol.Type = Mock1.self

    lazy var dest = try! Logger.Destination<Event>.new(configuration: self.mock.configuration).get()

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Make sure stub is ready for Monitor.performOutboxCleanup
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { _, _, _ in
            self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = nil
            return []
        }
    }

    func test_logic_isEnabledFor() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        let wait2 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2(nil)
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
        self.wait(for: .instant)
    }

    func test_logic_init_directoriesExist() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        let wait2 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2(nil)
        }
        self.fm.createDirectoryAtURLWithIntermediateDirectoriesAttributes = { _, _, _ in
            XCTFail()
        }
        _ = self.dest
        self.wait(for: .instant)
    }

    func test_logic_init_directoriesDontExist() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1(nil)
            return false
        }
        let wait2 = self.newWait(count: 3)
        var wait2Count = 0
        self.fm.createDirectoryAtURLWithIntermediateDirectoriesAttributes = { url, _, _ in
            wait2 {
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
            }
        }
        let wait3 = self.newWait()
        type(of: self.coor).addFilePresenter = { input in
            wait3 {
                XCTAssertTrue(input.isKind(of: Logger.Monitor.self))
            }
        }
        _ = self.dest
        self.wait(for: .instant)
    }

    func test_logic_init_error() {
        let wait = self.newWait()
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait(nil)
            isDirectory!.pointee = false
            return true
        }
        self.fm.createDirectoryAtURLWithIntermediateDirectoriesAttributes = { _, _, _ in
            XCTFail()
        }
        let result = Logger.Destination<Event>.new(configuration: self.mock.configuration)
        XCTAssertTrue(result.error!.isKind(of: .storageLocationCreate(nil)))
        self.wait(for: .instant)
    }

    func test_appendToInbox_success() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        let wait2 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2(nil)
        }
        let wait3 = self.newWait()
        self.fm.createFileAtPathWithContentsAttributes = { path, data, _ in
            wait3 {
                let url = URL(string: path)!
                XCTAssertEqual(url.deletingLastPathComponent().path, self.mock.configuration.storageLocation.inboxURL.path)
                let event = try! JSONDecoder().decode(Event.self, from: data!)
                XCTAssertEqual(event, self.mock.event)
            }
            return true
        }
        self.dest.appendToInbox(self.mock.event)
        self.wait(for: .instant)
    }

    func test_appendToInbox_error() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { path, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        let wait2 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2(nil)
        }
        let wait3 = self.newWait()
        self.fm.createFileAtPathWithContentsAttributes = { _, _, _ in
            wait3(nil)
            return false
        }
        let wait4 = self.newWait()
        self.errorDelegate.error = { error, _ in
            wait4 {
                if case .addToInbox(let url, _) = error {
                    XCTAssertEqual(url.deletingLastPathComponent(), self.mock.configuration.storageLocation.inboxURL)
                } else {
                    XCTFail("Wrong Error: \(error)")
                }
            }
        }
        self.dest.appendToInbox(self.mock.event)
        self.wait(for: .instant)
    }
}
