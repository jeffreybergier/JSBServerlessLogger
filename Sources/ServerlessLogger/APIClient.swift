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

extension Logger  {
    public class APIClient {
        
        public let configuration: Configuration
        private let session: URLSession
        
        init(configuration: Configuration) {
            let sessionConfiguration: URLSessionConfiguration
            if true { // TODO: replace with background allowed
                sessionConfiguration = URLSessionConfiguration.default
            } else {
                let sessionIdentifier = configuration.identifier  + "APIClient"
                sessionConfiguration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
            }
            sessionConfiguration.allowsCellularAccess = true
            sessionConfiguration.isDiscretionary = true
            sessionConfiguration.shouldUseExtendedBackgroundIdleMode = true
            #if !os(macOS)
                sessionConfiguration.sessionSendsLaunchEvents = true
            #endif
            
            // Delegate() here is safe because the docs say that URLSession
            // Holds a strong reference to its delegate until
            // invalidateAndCancel() or finishTasksAndInvalidate() are called
            self.session = URLSession(configuration: sessionConfiguration,
                                      delegate: Delegate(),
                                      delegateQueue: nil)
            self.configuration = configuration
        }
        
        deinit {
            self.session.finishTasksAndInvalidate()
        }
    }
}

extension Logger.APIClient {
    fileprivate class Delegate: NSObject, URLSessionDelegate {
        
    }
}
