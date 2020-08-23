//
//  Created by Jeffrey Bergier on 2020/08/19.
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

class APIClientMock1Tests: ParentTest {

    let mock: MockProtocol.Type = Mock1.self
    private let sessionDelegate = SessionDelegateStub()
    lazy var client = Logger.APIClient(configuration: self.mock.configuration,
                                       clientDelegate: nil,
                                       sessionDelegate: self.sessionDelegate)

    func test_send_secure() {
        self.fm.contentsAtPath = { _ in self.mock.onDisk.first!.1 }
        let wait1 = XCTestExpectation()
        let wait2 = XCTestExpectation()
        self.session.uploadTaskWithRequestFromFile = { request, onDiskURL in
            wait1.fulfill()
            XCTAssertEqual(request.url!.absoluteString,
                           "https://www.this-is-a-test.com?mac=BAlnJZfKW/66t0kguloks5YuDMTRuy3nhUc26YdftBE%3D")
            XCTAssertEqual(self.mock.onDisk.first!.url, onDiskURL)
            return FakeUploadTask
        }
        self.session.resumeTask = { _ in
            wait2.fulfill()
        }
        XCTAssertTrue(self.sessionDelegate.inFlight.isEmpty)
        self.client.send(payload: self.mock.onDisk.first!.url)
        XCTAssertEqual(self.sessionDelegate.inFlight.count, 1)
        self.wait(for: [wait1, wait2], timeout: 0.0)
    }
}

class APIClientMock2Tests: ParentTest {

    let mock: MockProtocol.Type = Mock2.self
    private let sessionDelegate = SessionDelegateStub()
    lazy var client = Logger.APIClient(configuration: self.mock.configuration,
                                       clientDelegate: nil,
                                       sessionDelegate: self.sessionDelegate)

    func test_send_insecure() {
        self.fm.contentsAtPath = { _ in self.mock.onDisk.first!.data }
        let wait1 = XCTestExpectation()
        let wait2 = XCTestExpectation()
        self.session.uploadTaskWithRequestFromFile = { request, onDiskURL in
            wait1.fulfill()
            XCTAssertEqual(request.url!.absoluteString,
                           "https://www.this-is-a-test.com")
            XCTAssertEqual(self.mock.onDisk.first!.url, onDiskURL)
            return FakeUploadTask
        }
        self.session.resumeTask = { _ in
            wait2.fulfill()
        }
        XCTAssertTrue(self.sessionDelegate.inFlight.isEmpty)
        self.client.send(payload: self.mock.onDisk.first!.url)
        XCTAssertEqual(self.sessionDelegate.inFlight.count, 1)
        self.wait(for: [wait1, wait2], timeout: 0.0)
    }
}

fileprivate class SessionDelegateStub: NSObject, ServerlessLoggerAPISessionDelegate {
    var inFlight = Dictionary<URL, URL>()
    var delegate: ServerlessLoggerAPIClientDelegate?
    func didCompleteTask(originalRequestURL: URL, responseStatusCode: Int, error: Error?) {}
}

fileprivate class ClientDelegateStub: ServerlessLoggerAPIClientDelegate {

    var didSendPayload: ((URL) -> Void)?
    var didFailToSend: ((URL) -> Void)?

    func didSend(payload: URL) {
        self.didSendPayload?(payload)
    }
    func didFailToSend(payload: URL) {
        self.didFailToSend?(payload)
    }
}

class APIClientSessionDelegateTests: ParentTest {

    let mock: MockProtocol.Type = Mock1.self
    lazy var sessionDelegate = Logger.APIClient.SessionDelegate(configuration: self.mock.configuration,
                                                                delegate: self.clientDelegate)
    private let clientDelegate = ClientDelegateStub()

    func test_didSendSuccessfully() {
        let remoteURL = self.mock.remoteURL.url!
        let onDiskURL = self.mock.onDisk.first!.url
        self.sessionDelegate.inFlight[remoteURL] = onDiskURL
        let wait = XCTestExpectation()
        self.clientDelegate.didSendPayload = { url in
            XCTAssertEqual(url, onDiskURL)
            wait.fulfill()
        }
        self.clientDelegate.didFailToSend = { _ in
            XCTFail("Did not expect failure")
        }
        self.sessionDelegate.didCompleteTask(originalRequestURL: remoteURL,
                                             responseStatusCode: 200,
                                             error: nil)
        XCTAssertTrue(self.sessionDelegate.inFlight.isEmpty)
        self.wait(for: [wait], timeout: 0.0)
    }

    func test_didFail_error() {
        let remoteURL = self.mock.remoteURL.url!
        let onDiskURL = self.mock.onDisk.first!.url
        self.sessionDelegate.inFlight[remoteURL] = onDiskURL
        self.clientDelegate.didSendPayload = { _ in
            XCTFail("Did not expect success")
        }
        let wait1 = XCTestExpectation()
        self.clientDelegate.didFailToSend = { url in
            XCTAssertEqual(url, onDiskURL)
            wait1.fulfill()
        }
        let wait2 = XCTestExpectation()
        self.errorDelegate.error = { error, _ in
            wait2.fulfill()
            XCTAssertTrue(error.isKind(of: .network(nil)))
        }
        let error = NSError(domain: "", code: 0, userInfo: nil)
        self.sessionDelegate.didCompleteTask(originalRequestURL: remoteURL,
                                             responseStatusCode: 200,
                                             error: error)
        XCTAssertTrue(self.sessionDelegate.inFlight.isEmpty)
        self.wait(for: [wait1, wait2], timeout: 0.0)
    }

    func test_didFail_statusCode() {
        let remoteURL = self.mock.remoteURL.url!
        let onDiskURL = self.mock.onDisk.first!.url
        self.sessionDelegate.inFlight[remoteURL] = onDiskURL
        self.clientDelegate.didSendPayload = { _ in
            XCTFail("Did not expect success")
        }
        let wait1 = XCTestExpectation()
        self.clientDelegate.didFailToSend = { url in
            XCTAssertEqual(url, onDiskURL)
            wait1.fulfill()
        }
        let wait2 = XCTestExpectation()
        self.errorDelegate.error = { error, _ in
            wait2.fulfill()
            XCTAssertTrue(error.isKind(of: .network(nil)))
        }
        self.sessionDelegate.didCompleteTask(originalRequestURL: remoteURL,
                                             responseStatusCode: 201,
                                             error: nil)
        XCTAssertTrue(self.sessionDelegate.inFlight.isEmpty)
        self.wait(for: [wait1, wait2], timeout: 0.0)
    }
}
