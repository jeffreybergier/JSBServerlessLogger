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

import Foundation

#if DEBUG

internal protocol NSFileCoordinatorProtocol: class {
    static func addFilePresenter(_ filePresenter: NSFilePresenter)
    func coordinate(writingItemAt: URL, options: Foundation.NSFileCoordinator.WritingOptions, writingItemAt: URL, options: Foundation.NSFileCoordinator.WritingOptions, error: NSErrorPointer, byAccessor: (URL, URL) -> Void)
    func coordinateMoving(from: URL, to: URL, accessor: (URL, URL) throws -> Void) throws
}

internal enum NSFileCoordinator {

    static func addFilePresenter(_ filePresenter: NSFilePresenter) {
        guard !IS_TESTING else {
            type(of: self.testReplacement!).addFilePresenter(filePresenter)
            return
        }
        if let replacement = self.testReplacement {
            type(of: replacement).addFilePresenter(filePresenter)
        } else {
            Foundation.NSFileCoordinator.addFilePresenter(filePresenter)
        }
    }

    internal static var testReplacement: NSFileCoordinatorProtocol?

    static func new(filePresenter: NSFilePresenter? = nil) -> NSFileCoordinatorProtocol
    {
        guard !IS_TESTING else { return self.testReplacement! }
        if let testReplacement = self.testReplacement { return testReplacement }
        return Foundation.NSFileCoordinator(filePresenter: filePresenter)
    }
}

extension Foundation.NSFileCoordinator: NSFileCoordinatorProtocol { }

#endif

extension Foundation.NSFileCoordinator {
    internal static func new(filePresenter: NSFilePresenter? = nil) -> Foundation.NSFileCoordinator
    {
        return Foundation.NSFileCoordinator(filePresenter: filePresenter)
    }
}
