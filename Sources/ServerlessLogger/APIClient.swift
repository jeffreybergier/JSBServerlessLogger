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

public protocol LoggerAPIClientDelegate: class {
    func didFinishSending(events: [URL])
}

extension Logger  {
    public class APIClient {
        
        public let configuration: Configuration
        public weak var delegate: LoggerAPIClientDelegate?
        private let session: URLSession
        private let sessionDelegate: Delegate
        
        init(configuration: Configuration) {
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
            var tasks = [URLSessionTask]()
            tasks.reserveCapacity(events.count)
            for url in events {
                autoreleasepool {
                    let data = try! Data(contentsOf: url)
                    let signature = data.hmacSignature(withSecret: "") // TODO: Fix this
                    var components = self.configuration.endpointURL
                    components.queryItems?.append(URLQueryItem(name: "mac", value: signature))
                    var request = URLRequest(url: components.url!)
                    request.httpMethod = "PUT"
                    let task = self.session.uploadTask(with: request, fromFile: url)
                    tasks.append(task)
                    task.resume()
                }
            }
        }
        
        deinit {
            self.session.finishTasksAndInvalidate()
        }
    }
}

extension Logger.APIClient {
    fileprivate class Delegate: NSObject, URLSessionTaskDelegate {
        
        #if !os(macOS)
        public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) { }
        #endif
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            
        }
    }
}
