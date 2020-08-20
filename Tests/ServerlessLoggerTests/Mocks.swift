//
//  Created by Jeffrey Bergier on 2020/08/19.
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

import CryptoKit
import Foundation
@testable import ServerlessLogger

protocol MockProtocol {
    static var onDiskURL: URL { get }
    static var onDiskData: Data { get }
    static var remoteURL: URLComponents { get }
    static var symmetricKey: SymmetricKey { get }
    static var configuration: ServerlessLoggerConfigurationProtocol { get }
}

enum Mock1: MockProtocol {
    static let onDiskURL = URL(string: "file:///ThisIsMyCoolFile")!
    static let onDiskData = "This is some data from the disk".data(using: .utf8)!
    static let remoteURL = URLComponents(string: "https://www.this-is-a-test.com")!
    static let symmetricKey = SymmetricKey(data: "Hello World".data(using: .utf8)!)
    static let configuration: ServerlessLoggerConfigurationProtocol = {
        let s = Logger.StorageLocation(baseDirectory: URL(string: "file:///baseDir")!,
                                       appName: "UnitTests",
                                       parentDirectory: "Mock1")
        let c = Logger.DefaultSecureConfiguration(endpointURL: remoteURL,
                                                  hmacKey: symmetricKey,
                                                  storageLocation: s)
        return c
    }()
}

enum Mock2: MockProtocol {
    static let onDiskURL = URL(string: "file:///ThisIsMyCoolFile")!
    static let onDiskData = "This is some data from the disk".data(using: .utf8)!
    static let remoteURL = URLComponents(string: "https://www.this-is-a-test.com")!
    static let symmetricKey = SymmetricKey(data: "Hello World".data(using: .utf8)!)
    static let configuration: ServerlessLoggerConfigurationProtocol = {
        let s = Logger.StorageLocation(baseDirectory: URL(string: "file:///baseDir")!,
                                       appName: "UnitTests",
                                       parentDirectory: "Mock2")
        let c = Logger.DefaultInsecureConfiguration(endpointURL: remoteURL, storageLocation: s)
        return c
    }()
}
