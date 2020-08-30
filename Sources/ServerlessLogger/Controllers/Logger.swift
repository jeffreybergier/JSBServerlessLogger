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
    
    public let configuration: ServerlessLoggerConfigurationProtocol
    
    // MARK: INIT
    /// Use if you prefer untyped errors. Use `new()` if you prefer typed errors
    public init(configuration: ServerlessLoggerConfigurationProtocol,
                includeDefaultXCGDestinations: Bool = true,
                includeDefaultJSBDestinations: Bool = true) throws
    {
        self.configuration = configuration
        super.init(identifier: configuration.identifier,
                   includeDefaultDestinations: includeDefaultXCGDestinations)
        guard includeDefaultJSBDestinations else { return }
        try self.add(destination: Destination<Event>(configuration: configuration))
    }

    /// Use if you prefer typed errors. Use `init()` if you prefer untyped errors
    open class func new(configuration: ServerlessLoggerConfigurationProtocol,
                        includeDefaultXCGDestinations: Bool = true,
                        includeDefaultJSBDestinations: Bool = true) -> Result<Logger, Logger.Error>
    {
        do {
            let logger = try Logger(configuration: configuration,
                                    includeDefaultXCGDestinations: includeDefaultXCGDestinations,
                                    includeDefaultJSBDestinations: includeDefaultJSBDestinations)
            return .success(logger)
        } catch {
            return .failure(error as! Logger.Error)
        }
    }

    // Internal INIT for testing only
    internal init(configuration: ServerlessLoggerConfigurationProtocol,
                  includeDefaultXCGDestinations: Bool = true,
                  destination: Destination<Event>)
    {
        self.configuration = configuration
        super.init(identifier: configuration.identifier,
                   includeDefaultDestinations: includeDefaultXCGDestinations)
        self.add(destination: destination)
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
