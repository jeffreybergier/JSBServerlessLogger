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

import Foundation
@testable import ServerlessLogger

class NSFileCoordinatorStubParent: NSFileCoordinatorProtocol {
    class func addFilePresenter(_ filePresenter: NSFilePresenter) {
        fatalError()
    }
    func coordinate(writingItemAt url1: URL,
                    options opt1: Foundation.NSFileCoordinator.WritingOptions,
                    writingItemAt url2: URL,
                    options opt2: Foundation.NSFileCoordinator.WritingOptions,
                    error: NSErrorPointer,
                    byAccessor: (URL, URL) -> Void)
    {
        fatalError()
    }
    func coordinateMoving(from: URL, to: URL, accessor: (URL, URL) throws -> Void) throws {
        fatalError()
    }
}

class NSFileCoordinatorClosureStub: NSFileCoordinatorStubParent {
    static var addFilePresenter: ((NSFilePresenter) -> Void)?
    var coordinateMovingFromURLToURLByAccessor: ((URL, URL, ((URL, URL) throws -> Void)) throws -> Void)?
    override class func addFilePresenter(_ filePresenter: NSFilePresenter) {
        self.addFilePresenter!(filePresenter)
    }
    override func coordinateMoving(from: URL, to: URL, accessor: (URL, URL) throws -> Void) throws {
        try self.coordinateMovingFromURLToURLByAccessor!(from, to, accessor)
    }
}
