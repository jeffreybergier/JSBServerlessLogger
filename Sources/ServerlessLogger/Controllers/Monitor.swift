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

        // Internal for testing only
        internal lazy var apiClient = APIClient(configuration: self.configuration, clientDelegate: self)
        // Underlying queue used for `presentedItemOperationQueue`
        private lazy var _presentedItemOperationQueue = DispatchQueue(label: configuration.identifier  + "Monitor",
                                                                      qos: .utility)

        public let configuration: ServerlessLoggerConfigurationProtocol

        /// Protocol conformance
        open lazy var presentedItemOperationQueue: OperationQueue = {
            let q = OperationQueue()
            q.underlyingQueue = _presentedItemOperationQueue
            return q
        }()

        /// Protocol conformance
        open lazy var presentedItemURL: URL? = {
            // This is called on an arbitary thread
            _presentedItemOperationQueue.async {
                // lazily populate the retry store once the NSFilePresenter
                // is configured. Strangely there is no delegate method
                // for `wasAddedAsFilePresenter`
                self.populateRetryStore()
                // Timers must be created on main thread
                DispatchQueue.main.async {
                    self.retryTimer.fire()
                }
            }
            return self.configuration.storageLocation.inboxURL
        }()

        /// When an Item fails to send, it is added to the `retryStore`. During a specified
        /// internval, the store is attempted to be resent via the `retryInboxOrOutboxItem` method
        open var retryStore: [URL] = []
        /// Helps to automatically retry failed sends during a specified time interval
        open lazy var retryTimer = Timer.scheduledTimer(timeInterval: self.configuration.timerDelay,
                                                        target: self,
                                                        selector: #selector(self.retryTimerFired(_:)),
                                                        userInfo: nil,
                                                        repeats: true)
        
        public init(configuration: ServerlessLoggerConfigurationProtocol) {
            self.configuration = configuration
            super.init()
        }

        /// Populates the retry array manually.
        /// Called only once when NSFilePresenter requests the presented URL
        /// After that, the retryStore is managed automatically when items fail to send
        open func populateRetryStore() {
            let fm = FileManager.default
            let dir = self.configuration.storageLocation
            let opts: Foundation.FileManager.DirectoryEnumerationOptions = [
                .skipsHiddenFiles,
                .skipsSubdirectoryDescendants,
                .skipsPackageDescendants
            ]
            var retries = (try? fm.contentsOfDirectory(at: dir.inboxURL,
                                                 includingPropertiesForKeys: nil,
                                                 options: opts)) ?? []
            retries += (try? fm.contentsOfDirectory(at: dir.outboxURL,
                                                    includingPropertiesForKeys: nil,
                                                    options: opts)) ?? []
            self.retryStore += retries
        }

        /// Iterates through `retryStore` and calls `retryInboxOrOutboxItem` for each item
        @objc open func retryTimerFired(_ timer: Timer) {
            _presentedItemOperationQueue.async {
                while !self.retryStore.isEmpty {
                    self.retryInboxOrOutboxItem(at: self.retryStore.popLast()!)
                }
            }
        }

        /// Precondition, file must be in Inbox or else crash
        /// Verifies the item meets all the requirements before sending:
        /// 1) That the file is in the inbox
        /// 2) It has the correct file extension
        /// 3) It exists
        /// 4) It is smaller than the file size limit configured
        open func tryInboxItem(at sourceURL: URL) {
            assert(sourceURL.deletingLastPathComponent() == self.configuration.storageLocation.inboxURL)
            guard self.filePreconditionsMet(at: sourceURL) else { return }
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
                NSDebugLog("JSBServerlessLogger: Monitor.tryInboxItem: "
                            + "Failed to move file: \(error)")
                self.configuration.errorDelegate?.logger(with: self.configuration,
                                                         produced: .moveToOutbox(error))
            }
        }

        /// URL must be in inbox or outbox
        open func retryInboxOrOutboxItem(at sourceURL: URL) {
            switch sourceURL.deletingLastPathComponent() {
            case self.configuration.storageLocation.inboxURL:
                self.tryInboxItem(at: sourceURL)
            case self.configuration.storageLocation.outboxURL:
                guard self.filePreconditionsMet(at: sourceURL) else { return }
                self.apiClient.send(payload: sourceURL)
            default:
                assertionFailure()
            }
        }
    }
}

extension Logger.Monitor: NSFilePresenter {

    /// Called when the Inbox changes
    open func presentedSubitemDidChange(at sourceURL: URL) {
        precondition(sourceURL.deletingLastPathComponent() == self.configuration.storageLocation.inboxURL)
        self.tryInboxItem(at: sourceURL)
    }

    private func filePreconditionsMet(at url: URL) -> Bool {
        switch url.deletingLastPathComponent() {
        case self.configuration.storageLocation.inboxURL,
             self.configuration.storageLocation.outboxURL:
            break
        default:
            return false
        }

        // verify the file has the correct extension
        let rhsExt = self.configuration.fileName.extension.lowercased()
        let lhsExt = url.pathExtension.lowercased()
        guard lhsExt == rhsExt else {
            NSDebugLog("JSBServerlessLogger: Monitor.presentedSubitemDidChange: "
                     + "Expected extension: \(rhsExt), Received: \(lhsExt), URL: \(url)")
            return false
        }

        // Resources returns NIL when the file doesn't exist, which is normal
        // because this function is also called after the file is moved out of INBOX
        guard
            let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
            let lhsSize = resources.fileSize
        else { return false }

        // verify the file size is less than the size limit
        let rhsSize = self.configuration.fileName.sizeLimit
        guard lhsSize <= rhsSize else {
            NSDebugLog("JSBServerlessLogger: Monitor.presentedSubitemDidChange: "
                     + "Expected size less than: \(rhsSize), Received: \(lhsSize), URL: \(url)")
            return false
        }

        return true
    }
}

extension Logger.Monitor: ServerlessLoggerAPIClientDelegate {

    /// Moves the file from the Outbox to the Sent folder
    /// precondition that the file must be in the outbox folder or else it crashes
    open func didSend(payload sourceURL: URL) {
        precondition(sourceURL.deletingLastPathComponent() == self.configuration.storageLocation.outboxURL)
        _presentedItemOperationQueue.async {
            guard self.filePreconditionsMet(at: sourceURL) else { return }
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

    /// Adds the file to the `retyStore`. Leaves the file in the Outbox folder
    /// precondition that the file must be in the outbox or else it crashes
    open func didFailToSend(payload sourceURL: URL) {
        precondition(sourceURL.deletingLastPathComponent() == self.configuration.storageLocation.outboxURL)
        _presentedItemOperationQueue.async {
            guard self.filePreconditionsMet(at: sourceURL) else { return }
            self.retryStore.append(sourceURL)
        }
    }
}
