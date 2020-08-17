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

public protocol ServerlessLoggerAPIClientDelegate: class {
    func didFinishSending(events: [URL])
}

extension Logger  {
    public class APIClient {
        
        public let configuration: ServerlessLoggerConfigurationProtocol
        public weak var delegate: ServerlessLoggerAPIClientDelegate?
        private let session: URLSession
        private let sessionDelegate: Delegate
        
        init(configuration: ServerlessLoggerConfigurationProtocol) {
            let sessionConfiguration: URLSessionConfiguration
            if true { // TODO: replace with background allowed
                sessionConfiguration = URLSessionConfiguration.default
            } else {
                let sessionIdentifier = configuration.identifier  + "APIClient"
                sessionConfiguration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
                #if !os(macOS)
                    sessionConfiguration.sessionSendsLaunchEvents = true
                #endif
            }
            sessionConfiguration.allowsCellularAccess = true
            sessionConfiguration.isDiscretionary = true
            sessionConfiguration.shouldUseExtendedBackgroundIdleMode = true
            
            let delegate = Delegate()
            self.session = URLSession(configuration: sessionConfiguration,
                                      delegate: delegate,
                                      delegateQueue: nil)
            self.configuration = configuration
            self.sessionDelegate = delegate
        }
        
        func send(events: [URL]) {
            for diskURL in events {
                var components = self.configuration.endpointURL
                if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *),
                   let secureConfig = self.configuration as? ServerlessLoggerHMACConfigurationProtocol
                {
                    // release the Data object as soon as possible in the loop
                    autoreleasepool {
                        let data = try! Data(contentsOf: diskURL)
                        let signature = data.hmacHash(with: secureConfig.hmacKey)
                        components.queryItems?.append(URLQueryItem(name: "mac", value: signature))
                    }
                } else {
                    #if DEBUG
                    NSLog("JSBServerlessLogger: Sending insecure payload")
                    #endif
                }
                let remoteURL = components.url!
                var request = URLRequest(url: remoteURL)
                request.httpMethod = "PUT"
                let task = self.session.uploadTask(with: request, fromFile: diskURL)
                self.sessionDelegate.inFlight[remoteURL] = diskURL
                task.resume()
            }
        }
        
        deinit {
            self.session.finishTasksAndInvalidate()
        }
    }
}

extension Logger.APIClient {
    fileprivate class Delegate: NSObject, URLSessionTaskDelegate {
        
        /// Key: RemoteURL, Value: OnDiskURL
        internal var inFlight = Dictionary<URL, URL>()
        
        #if !os(macOS)
        public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) { }
        #endif
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            // TODO: Implement checking off the tasks as they finish
        }
    }
}
