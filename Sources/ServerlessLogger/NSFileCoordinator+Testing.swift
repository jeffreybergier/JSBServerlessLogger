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

internal protocol NSFileCoordinatorProtocol: class {

    static func addFilePresenter(_ filePresenter: NSFilePresenter)

    func coordinateMoving(from: URL, to: URL, accessor: (URL, URL) throws -> Void) throws

    func coordinate(writingItemAt: URL, options: Foundation.NSFileCoordinator.WritingOptions, writingItemAt: URL, options: Foundation.NSFileCoordinator.WritingOptions, error: NSErrorPointer, byAccessor: (URL, URL) -> Void)
}

internal enum NSFileCoordinator {

    static func addFilePresenter(_ filePresenter: NSFilePresenter) {
        Foundation.NSFileCoordinator.addFilePresenter(filePresenter)
    }

    #if DEBUG
    internal static var testReplacement: NSFileCoordinatorProtocol?
    #endif

    static func new(filePresenter: NSFilePresenter? = nil) -> NSFileCoordinatorProtocol
    {
        #if DEBUG
        if let testReplacement = self.testReplacement { return testReplacement }
        #endif
        return Foundation.NSFileCoordinator(filePresenter: filePresenter)
    }
}

extension Foundation.NSFileCoordinator: NSFileCoordinatorProtocol { }
