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

extension Logger {
    open class Destination: DestinationProtocol {
        
        // MARK: Protocol Requirements
        public var owner: XCGLogger?
        public var identifier: String
        public var outputLevel: XCGLogger.Level
        public var haveLoggedAppDetails: Bool = false
        public var formatters: [LogFormatterProtocol]?
        public var filters: [FilterProtocol]?
        public var debugDescription: String { self.identifier }
        
        // MARK: Configuration
        public let configuration: Configuration
        
        // MARK: INIT
        public init(configuration: Configuration) throws {
            self.configuration = configuration
            self.identifier = configuration.identifier + "Destination"
            self.outputLevel = configuration.logLevel
            try self.createDirectoryStructureIfNeeded()
        }
        
        // MARK: Protocol Requirements
        open func process(logDetails: LogDetails) {
            //  TODO: Add writing to logmonitor
        }
        
        open func processInternal(logDetails: LogDetails) { }
        
        open func isEnabledFor(level: XCGLogger.Level) -> Bool {
            return level.rawValue >= self.outputLevel.rawValue
        }
        
        // MARK: Write to Inbox
        
        open func appendToInbox(_ event: Event) throws {
            // TODO: Imeplement add to inbox
            let jsonData = try JSONEncoder().encode(event)
            let url = self.configuration.inboxURL.appendingPathComponent(UUID().uuidString + ".event.json")
            let success = FileManager.default.createFile(atPath: url.path, contents: jsonData, attributes: nil)
            guard !success else { return }
            throw Error.writeToInboxError
        }
        
        // MARK: Destination Setup
        
        private func createDirectoryStructureIfNeeded() throws {
            let fm = FileManager.default
            let createDir: ((URL) throws -> Void) = { url in
                var isDirectory = ObjCBool.init(false)
                let exists = fm.fileExists(atPath: url.path, isDirectory: &isDirectory)
                if exists && !isDirectory.boolValue {
                    throw Error.destinationDirectorySetupError
                }
                if !exists {
                    try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                }
            }
            try createDir(self.configuration.inboxURL)
            try createDir(self.configuration.outboxURL)
            try createDir(self.configuration.sentURL)
        }
    }
}

extension Logger.Configuration {
    internal var inboxURL: URL {
        return self.directoryBase.appendingPathComponent(self.directoryAppName, isDirectory: true)
                                 .appendingPathComponent(self.directoryParentFolderName, isDirectory: true)
                                 .appendingPathComponent("Inbox", isDirectory: true)
    }
    internal var outboxURL: URL {
        return self.directoryBase.appendingPathComponent(self.directoryAppName, isDirectory: true)
                                 .appendingPathComponent(self.directoryParentFolderName, isDirectory: true)
                                 .appendingPathComponent("Outbox", isDirectory: true)
    }
    internal var sentURL: URL {
        return self.directoryBase.appendingPathComponent(self.directoryAppName, isDirectory: true)
                                 .appendingPathComponent(self.directoryParentFolderName, isDirectory: true)
                                 .appendingPathComponent("Sent", isDirectory: true)
    }
}
