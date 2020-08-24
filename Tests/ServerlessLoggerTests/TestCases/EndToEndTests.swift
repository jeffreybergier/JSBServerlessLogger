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

class EndToEndTests: LoggerTestCase {

    let mock: MockProtocol.Type = EndToEndMock1.self

    lazy var dest = try! Logger.Destination<Event>(configuration: self.mock.configuration)
    lazy var log = Logger(configuration: self.mock.configuration, destination: self.dest)

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Let regular session get created
        self.session = nil
        ServerlessLogger.URLSession.testReplacement = nil
        // Allow for Monitor.performOutboxCleanup
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { _, _, _ in
            self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = nil
            return []
        }
        // Allow Destination to check if directory structure exists
        var count = 0
        self.fm.fileExistsAtPathIsDirectory = { _, isDirectory in
            count += 1
            if count == 3 { self.fm.fileExistsAtPathIsDirectory = nil }
            isDirectory!.pointee = true
            return true
        }
        // Allow Monitor to be added as file presenter
        let coorType = type(of: self.coor!)
        coorType.addFilePresenter = { _ in
            coorType.addFilePresenter = nil
        }
    }

    func test_withHMAC() {
        var dataToSend: Data!
        let wait1 = self.newWait()
        self.fm.createFileAtPathWithContentsAttributes = { _, data, _ in
            wait1 {
                dataToSend = data
            }
            return data != nil ? true : false
        }
        self.log.error("")
        XCTAssertNotNil(dataToSend)
        let wait2 = self.newWait()
        self.fm.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions = { _, _, _ in
            wait2(nil)
            return [URL(string: "file:///hereismyfile.file")!]
        }
        self.dest.monitor.presentedItemDidChange()
        self.waitLong()
    }

}
