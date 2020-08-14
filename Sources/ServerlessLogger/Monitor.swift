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

extension Logger {
    open class Monitor {
        public let configuration: Configuration
        public init(configuration: Configuration) throws {
            self.configuration = configuration
            try self.createDirectoryStructureIfNeeded()
            // TODO: Implement monitoring of inbox folder
        }
        
        private func createDirectoryStructureIfNeeded() throws {
            let fm = FileManager.default
            let createDir: ((URL) throws -> Void) = { url in
                var isDirectory = ObjCBool.init(false)
                let exists = fm.fileExists(atPath: url.path, isDirectory: &isDirectory)
                if exists && !isDirectory.boolValue {
                    throw Error.directorySetupError
                }
                if !exists {
                    try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                }
            }
            try createDir(self.configuration.inboxURL)
            try createDir(self.configuration.outboxURL)
            try createDir(self.configuration.sentURL)
        }
        
        open func appendToInbox(_ event: Event) throws {
            // TODO: Imeplement add to inbox
        }
    }
}

extension Logger.Configuration {
    fileprivate var inboxURL: URL {
        return self.directoryBase.appendingPathComponent(self.directoryAppName, isDirectory: true)
                                 .appendingPathComponent(self.directoryParentFolderName, isDirectory: true)
                                 .appendingPathComponent("Inbox", isDirectory: true)
    }
    fileprivate var outboxURL: URL {
        return self.directoryBase.appendingPathComponent(self.directoryAppName, isDirectory: true)
                                 .appendingPathComponent(self.directoryParentFolderName, isDirectory: true)
                                 .appendingPathComponent("Outbox", isDirectory: true)
    }
    fileprivate var sentURL: URL {
        return self.directoryBase.appendingPathComponent(self.directoryAppName, isDirectory: true)
                                 .appendingPathComponent(self.directoryParentFolderName, isDirectory: true)
                                 .appendingPathComponent("Sent", isDirectory: true)
    }
}
