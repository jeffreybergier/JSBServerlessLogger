//
//  Created by Jeffrey Bergier on 2020/08/24.
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

#if DEBUG
/*
 // Uncomment and fill in missing pieces of EndToEndMock1 to run end to end tests
class EndToEndTests: AsyncDeprecateTestCase {

    let mock: MockProtocol.Type = EndToEndMock1.self

    lazy var log = try! Logger(configuration: self.mock.configuration)
    lazy var success = SuccessDelegateClosureStub()

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.mock.configuration.successDelegate = self.success
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        self.mock.configuration.successDelegate = nil
    }

    func test_withHMAC() {
        let wait = self.newWait()
        self.success.success = { _, _ in
            wait(nil)
        }
        self.log.error(NSError(domain: "JSBServerlessLoggingErrorDomain", code: -4444, userInfo: nil))
        self.waitSuperLong()
    }

}
*/
#endif
