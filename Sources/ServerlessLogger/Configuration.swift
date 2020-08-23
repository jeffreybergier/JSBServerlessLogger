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
    /// Extra details are added to each event. Use this to store UserID or any other useful iniformation
    var extraDetails: Event.ExtraDetails? { get }
    /// Log levels equal to this or higher will be logged via this system
    var logLevel: XCGLogger.Level { get }
    /// Specifies where logs are stored during the network request
    var storageLocation: Logger.StorageLocation { get }
    /// URL that the API Client uses to send PUT request
    var endpointURL: URLComponents { get }
    /// Error Delegate
    /// Because JSBServerlessLogger operates without user interaction
    /// there is no easy way to be notified when there are errors.
    /// If you would like to know when network request or other errors occur,
    /// set this delegate. Use a weak reference.
    /// Use a weak reference in custom implementations to prevent memory leaks
    var errorDelegate: ServerlessLoggerErrorDelegate? { get set }
}

@available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *)
public protocol ServerlessLoggerHMACConfigurationProtocol: ServerlessLoggerConfigurationProtocol {
    var hmacKey: SymmetricKey { get }
}

extension Logger {
    /// Folder structure created is:
    /// `{ baseDirectory }/{ appName }/{ parentDirectory }/Inbox`
    /// `{ baseDirectory }/{ appName }/{ parentDirectory }/Outbox`
    /// `{ baseDirectory }/{ appName }/{ parentDirectory }/Sent`
    public struct StorageLocation {
        /// Default is Application Support Directory
        public var baseDirectory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        /// Default is Main Bundle Identifier
        public var appName: String = Bundle.main.bundleIdentifier ?? "JSBServerlessLogger"
        /// Default is `ServerlessLogger`
        public var parentDirectory: String = "ServerlessLogger"
    }
}

extension Logger {
    public struct DefaultInsecureConfiguration: ServerlessLoggerConfigurationProtocol {
        public var endpointURL: URLComponents
        public var extraDetails: Event.ExtraDetails?

        public var identifier: String = "JSBServerlessLogger"
        public var logLevel: XCGLogger.Level = .error
        public var storageLocation = Logger.StorageLocation()
        public weak var errorDelegate: ServerlessLoggerErrorDelegate?
    }
    
    @available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *)
    public struct DefaultSecureConfiguration: ServerlessLoggerHMACConfigurationProtocol {
        public var endpointURL: URLComponents
        public var extraDetails: Event.ExtraDetails?
        public var hmacKey: SymmetricKey
        
        public var identifier: String = "JSBServerlessLogger"
        public var logLevel: XCGLogger.Level = .error
        public var storageLocation = Logger.StorageLocation()
        public weak var errorDelegate: ServerlessLoggerErrorDelegate?
    }
}
