//
//  Created by Jeffrey Bergier on 2020/08/13.
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

public protocol ServerlessLoggerErrorDelegate: class {
    func logger(with configuration: ServerlessLoggerConfigurationProtocol,
                produced error: Logger.Error)
}

#if DEBUG
public protocol ServerlessLoggerSuccessDelegate: class {
    func logger(with configuration: ServerlessLoggerConfigurationProtocol,
                successfullySent: URL)
}
#endif

extension Logger {
    public enum Error: CustomNSError {

        // MARK: Errors
        case storageLocationCreate(NSError?)
        case codable(NSError)
        case addToInbox(URL, Data)
        case moveToOutbox(NSError)
        case moveToSent(NSError)
        case moveToInbox(NSError)
        case network(NSError?)
        case location(URL)
        case fileExtension(URL)
        case fileSize(URL)
        case fileNotPresent(URL)
        case directorySizing(URL)

        // MARK: Protocol Conformance
        public static let errorDomain: String = "JSBServerlessLoggerErrorDomain"
        public var errorCode: Int {
            switch self {
            case .storageLocationCreate:
                return -1000
            case .codable:
                return -1001
            case .addToInbox:
                return -1002
            case .moveToInbox:
                return -1003
            case .moveToOutbox:
                return -1004
            case .moveToSent:
                return -1005
            case .network:
                return -1006
            case .location:
                return -1007
            case .fileExtension:
                return -1008
            case .fileSize:
                return -1009
            case .fileNotPresent:
                return -1010
            case .directorySizing:
                return -1011
            }
        }
        
        public var errorUserInfo: [String : Any] { return [:] }
    }
}
