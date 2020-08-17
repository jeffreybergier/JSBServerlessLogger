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
    open class Monitor: NSObject {
        
        open var presentedItemURL: URL? { self.configuration.storageLocation.inboxURL }
        open lazy var presentedItemOperationQueue: OperationQueue = {
            let q = OperationQueue()
            q.underlyingQueue = _presentedItemOperationQueue
            return q
        }()
        
        public let configuration: ServerlessLoggerConfigurationProtocol
        private lazy var apiClient = APIClient(configuration: self.configuration, delegate: self)
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
        let inboxLogURLs = try? fm.contentsOfDirectory(at: self.configuration.storageLocation.inboxURL,
                                                       includingPropertiesForKeys: nil,
                                                       options: [.skipsHiddenFiles,
                                                                 .skipsPackageDescendants,
                                                                 .skipsSubdirectoryDescendants])
        // TODO: Make network requests with URLs
    }
}

extension Logger.Monitor: ServerlessLoggerAPIClientDelegate {
    open func didSend(event sourceURL: URL) {
        _presentedItemOperationQueue.async {
            do {
                let destURL = self.configuration.storageLocation.sentURL
                try FileManager.default.moveItem(at: sourceURL, to: destURL)
            } catch {
                NSDebugLog("JSBServerlessLogger: Monitor.didSendURL: \(sourceURL): Failed to move item back to sentbox: \(error)")
            }
        }
    }
    
    open func didFailToSend(event sourceURL: URL) {
        _presentedItemOperationQueue.async {
            do {
                let destURL = self.configuration.storageLocation.inboxURL
                try FileManager.default.moveItem(at: sourceURL, to: destURL)
            } catch {
                NSDebugLog("JSBServerlessLogger: Monitor.didFailToSendURL: \(sourceURL): Failed to move item back to inbox: \(error)")
            }
        }
    }
}
