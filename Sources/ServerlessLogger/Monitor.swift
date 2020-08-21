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
    /// `Logger.Monitor` is responsible for monitoring files in the inbox.
    /// Also it moves files around appropriately when sending from the Outbox
    /// or placing things into Sent once they have been sent
    open class Monitor: NSObject {
        
        open var presentedItemURL: URL? { self.configuration.storageLocation.inboxURL }
        open lazy var presentedItemOperationQueue: OperationQueue = {
            let q = OperationQueue()
            q.underlyingQueue = _presentedItemOperationQueue
            return q
        }()
        
        public let configuration: ServerlessLoggerConfigurationProtocol

        // Internal for testing only
        internal lazy var apiClient = APIClient(configuration: self.configuration, clientDelegate: self)
        
        private lazy var _presentedItemOperationQueue = DispatchQueue(label: configuration.identifier  + "Monitor",
                                                                      qos: .utility)
        
        public init(configuration: ServerlessLoggerConfigurationProtocol) {
            self.configuration = configuration
        }
    }
}

extension Logger.Monitor: NSFilePresenter {
    open func presentedItemDidChange() {
        let fm = FileManager.default
        do {
            let inboxLogURLs = try fm.contentsOfDirectory(at: self.configuration.storageLocation.inboxURL,
                                                          includingPropertiesForKeys: nil,
                                                          options: [.skipsHiddenFiles,
                                                                    .skipsPackageDescendants,
                                                                    .skipsSubdirectoryDescendants])
            // TODO: Make network requests with URLs
            let c = NSFileCoordinator.new(filePresenter: self)
            for sourceURL in inboxLogURLs {
                let destURL = self.configuration.storageLocation.outboxURL
                                  .appendingPathComponent(sourceURL.lastPathComponent)
                try c.coordinateMoving(from: sourceURL, to: destURL) {
                    try fm.moveItem(at: $0, to: $1)
                }
                self.apiClient.send(payload: destURL)
            }
        } catch {
            NSDebugLog("JSBServerlessLogger: Monitor.presentedItemDidChange: Failed to move file: \(error)")
        }
    }
}

extension Logger.Monitor: ServerlessLoggerAPIClientDelegate {
    open func didSend(payload sourceURL: URL) {
        _presentedItemOperationQueue.async {
            do {
                let destURL = self.configuration.storageLocation.sentURL
                                  .appendingPathComponent(sourceURL.lastPathComponent)
                let c = NSFileCoordinator.new()
                let fm = FileManager.default
                try c.coordinateMoving(from: sourceURL, to: destURL) {
                    try fm.moveItem(at: $0, to: $1)
                }
            } catch {
                NSDebugLog("JSBServerlessLogger: Monitor.didSendURL: \(sourceURL): Failed to move item back to sentbox: \(error)")
            }
        }
    }
    
    open func didFailToSend(payload sourceURL: URL) {
        _presentedItemOperationQueue.async {
            do {
                let destURL = self.configuration.storageLocation.inboxURL
                                  .appendingPathComponent(sourceURL.lastPathComponent)
                let c = NSFileCoordinator.new()
                let fm = FileManager.default
                try c.coordinateMoving(from: sourceURL, to: destURL) {
                    try fm.moveItem(at: $0, to: $1)
                }
            } catch {
                NSDebugLog("JSBServerlessLogger: Monitor.didFailToSendURL: \(sourceURL): Failed to move item back to inbox: \(error)")
            }
        }
    }
}
