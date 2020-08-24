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
    /// When an Event is added to the inbox because it was logged, there is no delay waiting for a timer.
    /// However, when an Event fails to send, it is moved back to the Inbox. In this case, a timer is used to
    /// prevent repeating network connections that always fail.
    /// Default is 2 minutes.
    var timerDelay: TimeInterval { get }
    /// This feature is not currently supported
    var backgroundSession: Bool { get }
    /// Error Delegate
    /// Because JSBServerlessLogger operates without user interaction
    /// there is no easy way to be notified when there are errors.
    /// If you would like to know when network request or other errors occur,
    /// set this delegate. Use a weak reference.
    /// Use a weak reference in custom implementations to prevent memory leaks
    /// Note: DOES NOT execute on main thread
    var errorDelegate: ServerlessLoggerErrorDelegate? { get set }
    #if DEBUG
    var successDelegate: ServerlessLoggerSuccessDelegate? { get set }
    #endif
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
        public var baseDirectory: URL
        /// Default is Main Bundle Identifier
        public var appName: String
        /// Default is `ServerlessLogger`
        public var parentDirectory: String

        public init(baseDirectory: URL? = nil,
                    appName: String? = nil,
                    parentDirectory: String? = nil)
        {
            self.baseDirectory = baseDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.appName = appName ?? Bundle.main.bundleIdentifier ?? "JSBServerlessLogger"
            self.parentDirectory = parentDirectory ?? "ServerlessLogger"
        }
    }
}

// swiftlint:disable operator_usage_whitespace
extension Logger {
    public struct DefaultInsecureConfiguration: ServerlessLoggerConfigurationProtocol {
        public var endpointURL:        URLComponents
        public var extraDetails:       Event.ExtraDetails?
        public var identifier:         String
        public var logLevel:           XCGLogger.Level
        public var storageLocation:    Logger.StorageLocation
        public var timerDelay:         TimeInterval
        public var backgroundSession:  Bool
        public weak var errorDelegate: ServerlessLoggerErrorDelegate?
        #if DEBUG
        public weak var successDelegate: ServerlessLoggerSuccessDelegate?
        #endif

        public init(identifier:        String                         = "JSBServerlessLogger",
                    endpointURL:       URLComponents,
                    storageLocation:   Logger.StorageLocation         = Logger.StorageLocation(),
                    extraDetails:      Event.ExtraDetails?            = nil,
                    logLevel:          XCGLogger.Level                = .error,
                    timerDelay:        TimeInterval                   = 2*60,
                    backgroundSession: Bool                           = false,
                    errorDelegate:     ServerlessLoggerErrorDelegate? = nil)
        {
            self.endpointURL       = endpointURL
            self.extraDetails      = extraDetails
            self.identifier        = identifier
            self.logLevel          = logLevel
            self.storageLocation   = storageLocation
            self.timerDelay        = timerDelay
            self.backgroundSession = backgroundSession
            self.errorDelegate     = errorDelegate
        }
    }
    
    @available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *)
    public struct DefaultSecureConfiguration: ServerlessLoggerHMACConfigurationProtocol {
        public var endpointURL:        URLComponents
        public var extraDetails:       Event.ExtraDetails?
        public var hmacKey:            SymmetricKey
        public var identifier:         String
        public var logLevel:           XCGLogger.Level
        public var storageLocation:    Logger.StorageLocation
        public var timerDelay:         TimeInterval
        public var backgroundSession:  Bool
        public weak var errorDelegate: ServerlessLoggerErrorDelegate?
        #if DEBUG
        public weak var successDelegate: ServerlessLoggerSuccessDelegate?
        #endif

        public init(identifier:        String                         = "JSBServerlessLogger",
                    endpointURL:       URLComponents,
                    hmacKey:           SymmetricKey,
                    storageLocation:   Logger.StorageLocation         = Logger.StorageLocation(),
                    extraDetails:      Event.ExtraDetails?            = nil,
                    logLevel:          XCGLogger.Level                = .error,
                    timerDelay:        TimeInterval                   = 2*60,
                    backgroundSession: Bool                           = false,
                    errorDelegate:     ServerlessLoggerErrorDelegate? = nil)
        {
            self.hmacKey           = hmacKey
            self.endpointURL       = endpointURL
            self.extraDetails      = extraDetails
            self.identifier        = identifier
            self.logLevel          = logLevel
            self.storageLocation   = storageLocation
            self.timerDelay        = timerDelay
            self.backgroundSession = backgroundSession
            self.errorDelegate     = errorDelegate
        }
    }
}
// swiftlint:enable operator_usage_whitespace
