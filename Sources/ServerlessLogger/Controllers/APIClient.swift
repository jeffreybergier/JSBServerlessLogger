//
//  Created by Jeffrey Bergier on 2020/08/16.
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

public protocol ServerlessLoggerAPIClientDelegate: AnyObject {
    func didSend(payload: URL)
    func didFailToSend(payload: URL)
}

public protocol ServerlessLoggerAPISessionDelegate: URLSessionTaskDelegate {
    /// Manages internal state of tasks in progress
    var inFlight: Dictionary<URL, URL> { get set }
    /// Make weak to prevent memory leaks
    var delegate: ServerlessLoggerAPIClientDelegate? { get set }
    /// This method is expected to clean up internal state `inFlight` and then call `didSend` and `didFailToSend`
    /// on its `ServerlessLoggerAPIClientDelegate`.
    /// Expected to be called by URLSessionTaskDelegate `URLSession:task:didCompleteWithError:`
    /// after extracting the necessary information.
    func didCompleteTask(originalRequestURL: URL, responseStatusCode: Int, error: Error?)
}

extension Logger  {
    open class APIClient {
        
        public let configuration: ServerlessLoggerConfigurationProtocol
        private let session: URLSessionProtocol
        private let sessionDelegate: ServerlessLoggerAPISessionDelegate
        
        public init(configuration: ServerlessLoggerConfigurationProtocol,
             clientDelegate: ServerlessLoggerAPIClientDelegate?,
             sessionDelegate: ServerlessLoggerAPISessionDelegate? = nil)
        {
            let sessionConfiguration: URLSessionConfiguration
            if configuration.backgroundSession {
                // TODO: Add background networking support
                let sessionIdentifier = configuration.identifier  + "APIClient"
                sessionConfiguration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
                #if !os(macOS)
                    sessionConfiguration.sessionSendsLaunchEvents = true
                #endif
            } else {
                sessionConfiguration = URLSessionConfiguration.default
            }
            sessionConfiguration.allowsCellularAccess = true
            sessionConfiguration.isDiscretionary = true
            sessionConfiguration.shouldUseExtendedBackgroundIdleMode = true
            
            let sessionDelegate = sessionDelegate ?? SessionDelegate(configuration: configuration,
                                                                     delegate: clientDelegate)
            self.session = URLSession.new(configuration: sessionConfiguration,
                                          delegate: sessionDelegate,
                                          delegateQueue: nil)
            self.configuration = configuration
            self.sessionDelegate = sessionDelegate
        }
        
        open func send(payload onDiskURL: URL) {
            autoreleasepool {
                var components = self.configuration.endpointURL
                var insecure = true
                #if canImport(CryptoKit)
                if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *),
                   let secureConfig = self.configuration as? ServerlessLoggerHMACConfigurationProtocol,
                   let data = FileManager.default.contents(atPath: onDiskURL.path)
                {
                    let signature = data.hmacHash(with: secureConfig.hmacKey)
                    var queryItems = components.queryItems ?? []
                    queryItems.append(URLQueryItem(name: "mac", value: signature))
                    components.queryItems = queryItems
                    insecure = false
                }
                #endif
                if insecure {
                    NSDebugLog("JSBServerlessLogger: Sending payload without signature")
                }
                let remoteURL = components.url!
                var request = URLRequest(url: remoteURL)
                request.httpMethod = "PUT"
                let task = self.session.uploadTask(with: request, fromFile: onDiskURL)
                self.sessionDelegate.inFlight[remoteURL] = onDiskURL
                self.session.resume(task: task)
            }
        }
        
        deinit {
            self.session.finishTasksAndInvalidate()
        }
    }
}

extension Logger.APIClient {
    open class SessionDelegate: NSObject, ServerlessLoggerAPISessionDelegate {
        
        /// Key: RemoteURL, Value: OnDiskURL
        public var inFlight = Dictionary<URL, URL>()
        public weak var delegate: ServerlessLoggerAPIClientDelegate?
        public let configuration: ServerlessLoggerConfigurationProtocol
        
        public init(configuration: ServerlessLoggerConfigurationProtocol,
                    delegate: ServerlessLoggerAPIClientDelegate?)
        {
            self.configuration = configuration
            self.delegate = delegate
            super.init()
        }
        
        #if !os(macOS)
        public func urlSessionDidFinishEvents(forBackgroundURLSession session: Foundation.URLSession) { }
        #endif

        public func didCompleteTask(originalRequestURL remoteURL: URL, responseStatusCode: Int, error: Error?) {
            guard let onDiskURL = self.inFlight.removeValue(forKey: remoteURL) else { return }
            if let error = error {
                let error = error as NSError
                NSDebugLog("JSBServerlessError: didFailToSend: \(onDiskURL), error: \(error)")
                self.delegate?.didFailToSend(payload: onDiskURL)
                self.configuration.errorDelegate?.logger(with: self.configuration, produced: .network(error))
                return
            }
            guard responseStatusCode == 200 else {
                NSDebugLog("JSBServerlessError: didFailToSend: \(onDiskURL), responseStatusCode: \(String(describing: responseStatusCode))")
                self.delegate?.didFailToSend(payload: onDiskURL)
                self.configuration.errorDelegate?.logger(with: self.configuration, produced: .network(nil))
                return
            }
            self.delegate?.didSend(payload: onDiskURL)
        }
        
        public func urlSession(_: Foundation.URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let remoteURL = task.originalRequest?.url else {
                let message = "JSBServerlessError: Task Completed but missing required information: \(task)"
                NSDebugLog(message)
                assertionFailure(message)
                return
            }
            let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? -1
            self.didCompleteTask(originalRequestURL: remoteURL, responseStatusCode: statusCode, error: error)
        }
    }
}
