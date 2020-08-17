//
//  Created by Jeffrey Bergier on 2020/08/17.
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
import CryptoKit
import Foundation

public protocol ServerlessLoggerConfigurationProtocol {
    /// Identifier used for XCGLogger and Destination
    var identifier: String { get }
    /// UserID is included with log payload. If you have a way to identify your users, populate this field
    var userID: String? { get }
    /// Log levels equal to this or higher will be logged via this system
    var logLevel: XCGLogger.Level { get }
    /// Specifies where logs are stored during the network request
    var storageLocation: Logger.StorageLocation { get }
    /// URL that the API Client uses to send PUT request
    var endpointURL: URLComponents { get }
}

@available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *)
public protocol ServerlessLoggerHMACConfigurationProtocol: ServerlessLoggerConfigurationProtocol {
    var hmacKey: SymmetricKey { get }
}

extension Logger {
    
    /// Folder structure created is:
    /// `file:///{ baseDirectory }/{ appName }/{ parentDirectory }/Inbox`
    /// `file:///{ baseDirectory }/{ appName }/{ parentDirectory }/Outbox`
    /// `file:///{ baseDirectory }/{ appName }/{ parentDirectory }/Sent`
    public struct StorageLocation {
        public var baseDirectory: URL
        public var appName: String
        public var parentDirectory: String
    }
    
    // MARK: Configuration
    public struct Configuration2 {
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
        /// URL that the API Client uses to send PUT request
        public var endpointURL: URLComponents = URLComponents(string: "")! // TODO: Fix this
        
        public static let `default`: Configuration2 = .init()
    }
}
