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
        // TODO: Populate this with INBOX and OUTBOX items during INIT
        open var outboxItemsToRetry: [URL] = []
        open lazy var timer: Timer = {
            return Timer.scheduledTimer(timeInterval: self.configuration.timerDelay,
                                        target: self,
                                        selector: #selector(self.outboxTimerFired(_:)),
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
            guard !IS_TESTING else { return }
            // TODO: Populate outboxItemsToRetry with INBOX and OUTBOX items during INIT
            self.timer.fire()
        }

        @objc open func outboxTimerFired(_ timer: Timer) {
            _presentedItemOperationQueue.async {
                while !self.outboxItemsToRetry.isEmpty {
                    self.retryOutboxItem(at: self.outboxItemsToRetry.popLast()!)
                }
            }
        }

        open func tryInboxItem(at sourceURL: URL) {
            assert(sourceURL.deletingLastPathComponent() == self.configuration.storageLocation.inboxURL)
            do {
                let fm = FileManager.default
                let c = NSFileCoordinator.new(filePresenter: self)
                let destURL = self.configuration.storageLocation.outboxURL
                    .appendingPathComponent(sourceURL.lastPathComponent)
                try c.coordinateMoving(from: sourceURL, to: destURL) {
                    try fm.moveItem(at: $0, to: $1)
                }
                self.apiClient.send(payload: destURL)
            } catch {
                let error = error as NSError
                NSDebugLog("JSBServerlessLogger: Monitor.presentedItemDidChange: "
                            + "Failed to move file: \(error)")
                self.configuration.errorDelegate?.logger(with: self.configuration,
                                                         produced: .moveToOutbox(error))
            }
        }

        open func retryOutboxItem(at sourceURL: URL) {
            // TODO: If its outbox, do normal move code, if its inbox call inbox function
            switch sourceURL.deletingLastPathComponent() {
            case self.configuration.storageLocation.inboxURL:
                self.tryInboxItem(at: sourceURL)
            case self.configuration.storageLocation.outboxURL:
                do {
                    let fm = FileManager.default
                    let c = NSFileCoordinator.new(filePresenter: self)
                    let destURL = self.configuration.storageLocation.outboxURL
                        .appendingPathComponent(sourceURL.lastPathComponent)
                    try c.coordinateMoving(from: sourceURL, to: destURL) {
                        try fm.moveItem(at: $0, to: $1)
                    }
                    self.apiClient.send(payload: destURL)
                } catch {
                    let error = error as NSError
                    NSDebugLog("JSBServerlessLogger: Monitor.presentedItemDidChange: "
                                + "Failed to move file: \(error)")
                    self.configuration.errorDelegate?.logger(with: self.configuration,
                                                             produced: .moveToOutbox(error))
                }
            default:
                assertionFailure()
            }
        }
    }
}

extension Logger.Monitor: NSFilePresenter {

    open func presentedSubitemDidChange(at url: URL) {
        precondition(url.deletingLastPathComponent() == self.configuration.storageLocation.inboxURL)
        self.tryInboxItem(at: url)
    }
}

extension Logger.Monitor: ServerlessLoggerAPIClientDelegate {
    open func didSend(payload sourceURL: URL) {
        precondition(sourceURL.deletingLastPathComponent() == self.configuration.storageLocation.outboxURL)
        _presentedItemOperationQueue.async {
            do {
                let destURL = self.configuration.storageLocation.sentURL
                                  .appendingPathComponent(sourceURL.lastPathComponent)
                let c = NSFileCoordinator.new(filePresenter: self)
                let fm = FileManager.default
                try c.coordinateMoving(from: sourceURL, to: destURL) {
                    try fm.moveItem(at: $0, to: $1)
                }
                #if DEBUG
                self.configuration.successDelegate?.logger(with: self.configuration,
                                                           successfullySent: destURL)
                #endif
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
        precondition(sourceURL.deletingLastPathComponent() == self.configuration.storageLocation.outboxURL)
        _presentedItemOperationQueue.async {
            self.outboxItemsToRetry.append(sourceURL)
        }
    }
}
