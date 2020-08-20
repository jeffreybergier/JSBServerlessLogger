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

class URLSessionStubParent: URLSessionProtocol {

    func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        fatalError()
    }

    func resume(task: URLSessionTask) {
        fatalError()
    }

    func finishTasksAndInvalidate() {
        fatalError()
    }
}

class URLSessionClosureStub: URLSessionStubParent {

    var uploadTaskWithRequestFromFile: ((URLRequest, URL) -> URLSessionUploadTask)?
    var resumeTask: ((URLSessionTask) -> Void)?
    var finishTasksAndInvalidateClosure: (() -> Void)?

    override func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        return self.uploadTaskWithRequestFromFile?(request, fileURL) ?? FakeUploadTask
    }

    override func resume(task: URLSessionTask) {
        self.resumeTask?(task)
    }

    override func finishTasksAndInvalidate() {
        self.finishTasksAndInvalidateClosure?()
    }
}
