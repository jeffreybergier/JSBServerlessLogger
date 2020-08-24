//
//  Created by Jeffrey Bergier on 2020/08/22.
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

class LoggerMock1Tests: ParentTest {

    let mock: MockProtocol.Type = Mock1.self

    lazy var log = try! Logger.new(configuration: self.mock.configuration).get()

    func test_logError() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { url, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        let wait2 = self.newWait()
        self.fm.createFileAtPathWithContentsAttributes = { path, data, _ in
            wait2 {
                let url = URL(string: path)!
                XCTAssertEqual(url.deletingLastPathComponent().path, self.mock.configuration.storageLocation.inboxURL.path)
                let event = try! JSONDecoder().decode(Event.self, from: data!)
                XCTAssertEqual(event.errorDetails!.code, -4444)
                XCTAssertEqual(event.errorDetails!.domain, "Test")
            }
            return true
        }
        let wait3 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait3(nil)
        }
        self.log.error(NSError(domain: "Test", code: -4444, userInfo: nil))
        self.waitInstant()
    }

    func test_logDebug() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { url, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        self.fm.createFileAtPathWithContentsAttributes = { path, data, _ in
            self.main { XCTFail() }
            return true
        }
        let wait2 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2(nil)
        }
        self.log.debug(NSError(domain: "Test", code: -4444, userInfo: nil))
        self.waitInstant()
    }
}

class LoggerMock2Tests: ParentTest {

    let mock: MockProtocol.Type = Mock2.self

    lazy var log = try! Logger.new(configuration: self.mock.configuration).get()

    func test_logDebug() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { url, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        let wait2 = self.newWait()
        self.fm.createFileAtPathWithContentsAttributes = { path, data, _ in
            wait2 {
                let url = URL(string: path)!
                XCTAssertEqual(url.deletingLastPathComponent().path, self.mock.configuration.storageLocation.inboxURL.path)
                let event = try! JSONDecoder().decode(Event.self, from: data!)
                XCTAssertEqual(event.errorDetails!.code, -4444)
                XCTAssertEqual(event.errorDetails!.domain, "Test")
            }
            return true
        }
        let wait3 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait3(nil)
        }
        self.log.debug(NSError(domain: "Test", code: -4444, userInfo: nil))
        self.waitInstant()
    }

    func test_logVerbose() {
        let wait1 = self.newWait(count: 3)
        self.fm.fileExistsAtPathIsDirectory = { url, isDirectory in
            wait1(nil)
            isDirectory!.pointee = true
            return true
        }
        self.fm.createFileAtPathWithContentsAttributes = { path, data, _ in
            self.main { XCTFail() }
            return true
        }
        let wait2 = self.newWait()
        type(of: self.coor!).addFilePresenter = { _ in
            wait2(nil)
        }
        self.log.verbose(NSError(domain: "Test", code: -4444, userInfo: nil))
        self.waitInstant()
    }
}