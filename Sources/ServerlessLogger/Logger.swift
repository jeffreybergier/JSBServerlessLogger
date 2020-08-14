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

import XCGLogger
import Foundation

open class Logger: XCGLogger {
    
    // MARK: Configuration
    public struct Configuration {
        /// Identifier used for XCGLogger and Destination
        public var identifier: String = "JSBServerlessLogger"
        /// UserID is included with log payload. If you have a way to identify your users, populate this field
        public var userID: String?
        /// Log levels equal to this or higher will be logged via this system
        public var logLevel: XCGLogger.Level = .error
        /// Default is User's Application Support Directory
        public var directoryBase = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        /// Default is main bundle identifier
        public var directoryAppName: String = Bundle.main.bundleIdentifier ?? "JSBServerlessLogger"
        /// Parent structure for logger. Inside this folder, Inbox, Outbox, and Sent folders will be created
        public var directoryParentFolderName: String = "ServerlessLogger"
        
        public static let `default`: Configuration = .init()
    }
    
    public let configuration: Configuration
    
    // MARK: INIT
    public init(configuration: Configuration = .default,
                includeDefaultDestinations: Bool = true)
    {
        self.configuration = configuration
        super.init(identifier: configuration.identifier,
                   includeDefaultDestinations: includeDefaultDestinations)
        guard includeDefaultDestinations else { return }
        self.add(destination: Destination(configuration: configuration))
    }
    
    // MARK: Custom
    // Attempt to extract NSError objects from log closure
    open override func logln(_ level: Level = .debug,
                             functionName: String = #function,
                             fileName: String = #file,
                             lineNumber: Int = #line,
                             userInfo: [String: Any] = [:],
                             closure: () -> Any?)
    {
        guard level.rawValue >= self.configuration.logLevel.rawValue else {
            super.logln(level,
                        functionName: functionName,
                        fileName: fileName,
                        lineNumber: lineNumber,
                        userInfo: userInfo,
                        closure: closure)
            return
        }
        
        var userInfo = userInfo
        if let closureResult = closure() as? NSError {
            userInfo[Event.kErrorKey] = closureResult
        }
        super.logln(level,
                    functionName: functionName,
                    fileName: fileName,
                    lineNumber: lineNumber,
                    userInfo: userInfo,
                    closure: closure)
    }
}
