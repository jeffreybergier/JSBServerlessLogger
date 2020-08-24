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

public protocol ServerlessLoggerEventProtocol: Codable {
    init(configuration: ServerlessLoggerConfigurationProtocol, details: LogDetails)
}

extension Logger {
    open class Destination<T: ServerlessLoggerEventProtocol>: DestinationProtocol {
        
        // MARK: Protocol Requirements
        public var owner: XCGLogger?
        public var identifier: String
        public var outputLevel: XCGLogger.Level
        public var haveLoggedAppDetails: Bool = false
        public var formatters: [LogFormatterProtocol]?
        public var filters: [FilterProtocol]?
        public var debugDescription: String { self.identifier }
        
        // MARK: Configuration
        public let configuration: ServerlessLoggerConfigurationProtocol
        // internal for testing only
        internal let monitor: Monitor
        
        // MARK: INIT
        /// Use if you prefer untyped errors. Use `new()` if you prefer typed errors
        public init(configuration: ServerlessLoggerConfigurationProtocol) throws {
            self.configuration = configuration
            self.monitor = Monitor(configuration: configuration)
            self.identifier = configuration.identifier + "Destination"
            self.outputLevel = configuration.logLevel
            try self.createDirectoryStructureIfNeeded()
            NSFileCoordinator.addFilePresenter(self.monitor)
        }

        /// Use if you prefer typed errors. Use `init()` if you prefer untyped errors
        open class func new(configuration: ServerlessLoggerConfigurationProtocol)
                            -> Result<Destination<T>, Logger.Error>
        {
            do {
                let dest = try Destination<T>(configuration: configuration)
                return .success(dest)
            } catch {
                return .failure(error as! Logger.Error)
            }
        }
        
        // MARK: Protocol Requirements
        
        open func processInternal(logDetails: LogDetails) { }
        
        open func isEnabledFor(level: XCGLogger.Level) -> Bool {
            return level.rawValue >= self.outputLevel.rawValue
        }
        
        // MARK: Write to Inbox

        open func process(logDetails: LogDetails) {
            let event = T(configuration: self.configuration, details: logDetails)
            self.appendToInbox(event)
        }
        
        open func appendToInbox(_ event: T) {
            do {
                let jsonData = try JSONEncoder().encode(event)
                let destURL = self.configuration.storageLocation.inboxURL
                                  .appendingPathComponent(UUID().uuidString + ".event.json")
                let success = FileManager.default.createFile(atPath: destURL.path,
                                                             contents: jsonData,
                                                             attributes: nil)
                guard !success else { return }
                NSDebugLog("JSBServerlessLogger: Error Writing To Inbox: \(event)")
                self.configuration.errorDelegate?.logger(
                    with: self.configuration,
                    produced: .addToInbox(destURL, jsonData)
                )
            } catch {
                NSDebugLog("JSBServerlessLogger: Error Encoding Event: \(event)")
                self.configuration.errorDelegate?.logger(
                    with: self.configuration,
                    produced: .codable(error as NSError)
                )
            }
        }
        
        // MARK: Destination Setup
        
        private func createDirectoryStructureIfNeeded() throws {
            let fm = FileManager.default
            let createDir: ((URL) throws -> Void) = { url in
                var isDirectory = ObjCBool.init(false)
                let exists = fm.fileExists(atPath: url.path, isDirectory: &isDirectory)
                if exists && !isDirectory.boolValue {
                    NSDebugLog("JSBServerlessLogger: File exists where directory should be: \(url)")
                    throw Error.storageLocationCreate(nil)
                }
                if !exists {
                    do {
                        try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        NSDebugLog("JSBServerlessLogger: Failed to create directory: \(url)")
                        throw Error.storageLocationCreate(error as NSError)
                    }
                }
            }
            try createDir(self.configuration.storageLocation.inboxURL)
            try createDir(self.configuration.storageLocation.outboxURL)
            try createDir(self.configuration.storageLocation.sentURL)
        }
    }
}

extension Logger.StorageLocation {
    private var storageLocationURL: URL {
        return self.baseDirectory.appendingPathComponent(self.appName, isDirectory: true)
                                 .appendingPathComponent(self.parentDirectory, isDirectory: true)
    }
    internal var inboxURL: URL {
        return storageLocationURL.appendingPathComponent("Inbox", isDirectory: true)
    }
    internal var outboxURL: URL {
        return storageLocationURL.appendingPathComponent("Outbox", isDirectory: true)
    }
    internal var sentURL: URL {
        return storageLocationURL.appendingPathComponent("Sent", isDirectory: true)
    }
}
