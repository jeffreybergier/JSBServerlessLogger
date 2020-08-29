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

extension XCGLogger.Level: Codable { }
private let dateFormatter = ISO8601DateFormatter()

// swiftlint:disable operator_usage_whitespace
extension Event: ServerlessLoggerEventProtocol {
    
    public init(configuration: ServerlessLoggerConfigurationProtocol, details: LogDetails) {
        self.deviceDetails = .init()
        self.logDetails    = .init(details)
        self.errorDetails  = (details.userInfo[Event.kErrorKey] as? NSError).map { .init($0) }
        self.extraDetails  = configuration.extraDetails
    }
    
    public struct JSBLogDetails: Codable, Equatable {
        
        public var level:        String
        public var date:         String
        public var message:      String
        public var functionName: String
        public var fileName:     String
        public var lineNumber:   Int
        
        public init(_ input: LogDetails) {
            self.init(level: input.level,
                      date: input.date,
                      message: input.message,
                      functionName: input.functionName,
                      fileName: input.fileName,
                      lineNumber: input.lineNumber)
        }

        public init(level:        XCGLogger.Level,
                    date:         Date,
                    message:      String,
                    functionName: String,
                    fileName:     String,
                    lineNumber:   Int)
        {
            self.level        = level.description
            self.date         = dateFormatter.string(from: date)
            self.message      = message
            self.functionName = functionName
            self.fileName     = URL(fileURLWithPath: fileName).lastPathComponent
            self.lineNumber   = lineNumber
        }
    }
}
// swiftlint:enable operator_usage_whitespace
