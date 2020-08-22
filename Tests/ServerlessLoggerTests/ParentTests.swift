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
@testable import ServerlessLogger

class ParentTest: XCTestCase {

    var fm: FileManagerClosureStub!
    var coor: NSFileCoordinatorClosureStub!
    var session: URLSessionClosureStub!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let fm = FileManagerClosureStub()
        let session = URLSessionClosureStub()
        let coor = NSFileCoordinatorClosureStub()
        ServerlessLogger.FileManager.default = fm
        ServerlessLogger.URLSession.testReplacement = session
        ServerlessLogger.NSFileCoordinator.testReplacement = coor
        self.fm = fm
        self.session = session
        self.coor = coor
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        ServerlessLogger.FileManager.default = nil
        ServerlessLogger.URLSession.testReplacement = nil
        ServerlessLogger.NSFileCoordinator.testReplacement = nil
        self.fm = nil
        self.session = nil
        self.coor = nil
    }
}
