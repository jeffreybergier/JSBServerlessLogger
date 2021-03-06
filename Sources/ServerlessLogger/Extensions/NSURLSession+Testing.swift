//
//  Created by Jeffrey Bergier on 2020/08/18.
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

@objc internal protocol URLSessionProtocol {
    
    @objc(uploadTaskWithRequest:fromFile:)
    func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask
    func resume(task: URLSessionTask)
    func finishTasksAndInvalidate()
}

internal enum URLSession {

    #if DEBUG
    internal static var testReplacement: URLSessionProtocol?
    #endif
    
    static func new(configuration: URLSessionConfiguration,
                    delegate: URLSessionDelegate?,
                    delegateQueue queue: OperationQueue?) -> URLSessionProtocol
    {
        #if DEBUG
        if let testReplacement = self.testReplacement { return testReplacement }
        #endif
        return Foundation.URLSession(configuration: configuration,
                                     delegate: delegate,
                                     delegateQueue: queue)
    }
}

extension Foundation.URLSession: URLSessionProtocol {
    func resume(task: URLSessionTask) {
        task.resume()
    }
}
