//
//  Created by Jeffrey Bergier on 2020/08/23.
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
import ServerlessLogger

class ErrorDelegateClosureStub: ServerlessLoggerErrorDelegate {
    var error: ((Logger.Error, ServerlessLoggerConfigurationProtocol) -> Void)?

    func logger(with configuration: ServerlessLoggerConfigurationProtocol,
                produced error: Logger.Error)
    {
        self.error!(error, configuration)
    }
}

extension Logger.Error {
    func isKind(of error: Logger.Error) -> Bool {
        let lhs = self
        let rhs = error
        switch lhs {
        case .storageLocationCreate:
            if case .storageLocationCreate = rhs { return true }
            return false
        case .codable:
            if case .codable = rhs { return true }
            return false
        case .addToInbox:
            if case .addToInbox = rhs { return true }
            return false
        case .moveToOutbox:
            if case .moveToOutbox = rhs { return true }
            return false
        case .moveToSent:
            if case .moveToSent = rhs { return true }
            return false
        case .moveToInbox:
            if case .moveToInbox = rhs { return true }
            return false
        case .network:
            if case .network = rhs { return true }
            return false
        }
    }
}
