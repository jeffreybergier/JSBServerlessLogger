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

        public let configuration: ServerlessLoggerConfigurationProtocol
        open var presentedItemURL: URL? { self.configuration.storageLocation.inboxURL }
        open lazy var presentedItemOperationQueue: OperationQueue = {
            let q = OperationQueue()
            q.underlyingQueue = _presentedItemOperationQueue
            return q
        }()
        open lazy var timer: Timer = {
            return Timer.scheduledTimer(timeInterval: self.configuration.timerDelay,
                                        target: self,
                                        selector: #selector(self.presentedItemDidChange),
                                        userInfo: nil,
                                        repeats: true)
        }()

        // Internal for testing only
        internal lazy var apiClient = APIClient(configuration: self.configuration, clientDelegate: self)
        
        private lazy var _presentedItemOperationQueue = DispatchQueue(label: configuration.identifier  + "Monitor",
                                                                      qos: .utility)
        
        public init(configuration: ServerlessLoggerConfigurationProtocol) {
            self.configuration = configuration
            super.init()
            self.performOutboxCleanup()
            guard !IS_TESTING else { return }
            // only fire the timer during init if we are not testing
            self.timer.fire()
        }

        /// Only run on Init
        open func performOutboxCleanup() {
            let fm = FileManager.default!
            do {
                let outboxLogURLs = try fm.contentsOfDirectory(at: self.configuration.storageLocation.outboxURL,
                                                               includingPropertiesForKeys: nil,
                                                               options: [.skipsHiddenFiles,
                                                                         .skipsPackageDescendants,
                                                                         .skipsSubdirectoryDescendants])
                let c = NSFileCoordinator.new(filePresenter: self)
                for sourceURL in outboxLogURLs {
                    let destURL = self.configuration.storageLocation.inboxURL
                                      .appendingPathComponent(sourceURL.lastPathComponent)
                    try c.coordinateMoving(from: sourceURL, to: destURL) {
                        try fm.moveItem(at: $0, to: $1)
                    }
                    self.apiClient.send(payload: destURL)
                }
            } catch {
                let error = error as NSError
                NSDebugLog("JSBServerlessLogger: Monitor.performOutboxCleanup: "
                            + "Failed to move file: \(error)")
                self.configuration.errorDelegate?.logger(with: self.configuration,
                                                         produced: .moveToInbox(error))
            }
        }
    }
}

extension Logger.Monitor: NSFilePresenter {
    open func presentedItemDidChange() {
        _presentedItemOperationQueue.async {
            let fm = FileManager.default!
            do {
                let inboxLogURLs = try fm.contentsOfDirectory(at: self.configuration.storageLocation.inboxURL,
                                                              includingPropertiesForKeys: nil,
                                                              options: [.skipsHiddenFiles,
                                                                        .skipsPackageDescendants,
                                                                        .skipsSubdirectoryDescendants])
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
                let error = error as NSError
                NSDebugLog("JSBServerlessLogger: Monitor.presentedItemDidChange: "
                            + "Failed to move file: \(error)")
                self.configuration.errorDelegate?.logger(with: self.configuration,
                                                         produced: .moveToOutbox(error))
            }
        }
    }
}

extension Logger.Monitor: ServerlessLoggerAPIClientDelegate {
    open func didSend(payload sourceURL: URL) {
        _presentedItemOperationQueue.async {
            do {
                let destURL = self.configuration.storageLocation.sentURL
                                  .appendingPathComponent(sourceURL.lastPathComponent)
                let c = NSFileCoordinator.new(filePresenter: self)
                let fm = FileManager.default!
                try c.coordinateMoving(from: sourceURL, to: destURL) {
                    try fm.moveItem(at: $0, to: $1)
                }
            } catch {
                let error = error as NSError
                NSDebugLog("JSBServerlessLogger: Monitor.didSendURL: \(sourceURL): "
                            + "Failed to move item back to sentbox: \(error)")
                self.configuration.errorDelegate?.logger(with: self.configuration,
                                                         produced: .moveToSent(error))
            }
        }
    }
    
    open func didFailToSend(payload sourceURL: URL) {
        _presentedItemOperationQueue.async {
            do {
                let destURL = self.configuration.storageLocation.inboxURL
                                  .appendingPathComponent(sourceURL.lastPathComponent)
                let c = NSFileCoordinator.new(filePresenter: self)
                let fm = FileManager.default!
                try c.coordinateMoving(from: sourceURL, to: destURL) {
                    try fm.moveItem(at: $0, to: $1)
                }
            } catch {
                let error = error as NSError
                NSDebugLog("JSBServerlessLogger: Monitor.didFailToSendURL: "
                           + "\(sourceURL): Failed to move item back to inbox: \(error)")
                self.configuration.errorDelegate?.logger(with: self.configuration,
                                                         produced: .moveToInbox(error))
            }
        }
    }
}
