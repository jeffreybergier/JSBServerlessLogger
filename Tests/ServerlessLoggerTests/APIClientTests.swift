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

class APIClientTests: XCTestCase {

    static let mock = Mock1.self
    let fm = FileManagerClosureStub()
    let session = URLSessionClosureStub()
    private let sessionDelegate = SessionDelegate()
    lazy var client = Logger.APIClient(configuration: APIClientTests.mock.configuration,
                                       clientDelegate: nil,
                                       sessionDelegate: self.sessionDelegate)

    override func setUpWithError() throws {
        try super.setUpWithError()
        ServerlessLogger.FileManager.default = self.fm
        ServerlessLogger.URLSession.testReplacement = self.session
    }

    func test_send_secure() {
        self.fm.contentsAtPath = { _ in APIClientTests.mock.onDiskData }
        let wait = XCTestExpectation()
        wait.expectedFulfillmentCount = 1
        self.session.uploadTaskWithRequestFromFile = { request, onDiskURL in
            wait.fulfill()
            XCTAssertEqual(request.url!.absoluteString,
                           "https://www.this-is-a-test.com?mac=BAlnJZfKW/66t0kguloks5YuDMTRuy3nhUc26YdftBE%3D")
            XCTAssertEqual(APIClientTests.mock.onDiskURL, onDiskURL)
            return URLSessionUploadTask()
        }
        XCTAssertTrue(self.sessionDelegate.inFlight.isEmpty)
        self.client.send(payload: APIClientTests.mock.onDiskURL)
        XCTAssertEqual(self.sessionDelegate.inFlight.count, 1)
        self.wait(for: [wait], timeout: 0.0)
    }

}

fileprivate class SessionDelegate: NSObject, ServerlessLoggerAPISessionDelegate {
    var inFlight = Dictionary<URL, URL>()
    var delegate: ServerlessLoggerAPIClientDelegate? = nil
}
