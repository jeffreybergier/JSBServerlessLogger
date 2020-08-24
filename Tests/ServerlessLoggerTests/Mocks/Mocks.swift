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
import ServerlessLogger


protocol MockProtocol {
    typealias OnDisk = (url: URL, data: Data)
    static var onDisk: [OnDisk] { get }
    static var remoteURL: URLComponents { get }
    static var symmetricKey: SymmetricKey { get }
    static var event: Event { get }
    static var configuration: ServerlessLoggerConfigurationProtocol { get set }
}

enum Mock1: MockProtocol {
    static let onDisk: [OnDisk] = [
        (URL(string: "file:///baseDir/UnitTests/Mock1/Inbox/567890.file")!, "This is some data from the disk".data(using: .utf8)!)
    ]
    static let remoteURL = URLComponents(string: "https://www.this-is-a-test.com")!
    static let symmetricKey = SymmetricKey(data: "Hello World".data(using: .utf8)!)
    static var configuration: ServerlessLoggerConfigurationProtocol = {
        let s = Logger.StorageLocation(baseDirectory: URL(string: "file:///baseDir")!,
                                       appName: "UnitTests",
                                       parentDirectory: "Mock1")
        var c = Logger.DefaultSecureConfiguration(endpointURL: remoteURL,
                                                  hmacKey: symmetricKey,
                                                  storageLocation: s)
        c.logLevel = .error
        return c
    }()
    static var event: Event = {
        let details = ServerlessLogger.Event.JSBLogDetails(level: .debug,
                                                           date: Date(),
                                                           message: "Mock1EventMessage",
                                                           functionName: "Mock1FunctionName",
                                                           fileName: "Mock1FileName",
                                                           lineNumber: 1000)
        let event = ServerlessLogger.Event(incident: "Mock1Incident",
                                           logDetails: details,
                                           errorDetails: nil,
                                           extraDetails: nil)
        return event
    }()
}

enum Mock2: MockProtocol {
    static let onDisk: [OnDisk] = [
        (URL(string: "file:///baseDir/UnitTests/Mock2/Inbox/12345.file")!, "This is some data from the disk".data(using: .utf8)!)
    ]
    static let remoteURL = URLComponents(string: "https://www.this-is-a-test.com")!
    static let symmetricKey = SymmetricKey(data: "Hello World".data(using: .utf8)!)
    static var configuration: ServerlessLoggerConfigurationProtocol = {
        let s = Logger.StorageLocation(baseDirectory: URL(string: "file:///baseDir")!,
                                       appName: "UnitTests",
                                       parentDirectory: "Mock2")
        var c = Logger.DefaultInsecureConfiguration(endpointURL: remoteURL, storageLocation: s)
        c.logLevel = .debug
        return c
    }()
    static var event: Event = {
        let details = Event.JSBLogDetails(level: .debug,
                                          date: Date(),
                                          message: "Mock2EventMessage",
                                          functionName: "Mock2FunctionName",
                                          fileName: "Mock2FileName",
                                          lineNumber: 1000)
        let event = Event(incident: "Mock2Incident",
                          logDetails: details,
                          deviceDetails: .init(),
                          errorDetails: nil,
                          extraDetails: nil)
        return event
    }()
}

enum EndToEndMock1: MockProtocol {
    static let onDisk: [OnDisk] = []
    static let remoteURL = URLComponents(string: { () -> String in fatalError("Put your endpoint here") }())!
    static let symmetricKey = SymmetricKey(data: Data(base64Encoded: { () -> String in fatalError("Put your secret here") }())!)
    static var configuration: ServerlessLoggerConfigurationProtocol = {
        let s = Logger.StorageLocation(baseDirectory: URL(string: "file:///baseDir")!,
                                       appName: "UnitTests",
                                       parentDirectory: "EndToEndMock1")
        var c = Logger.DefaultSecureConfiguration(endpointURL: remoteURL,
                                                  hmacKey: symmetricKey,
                                                  storageLocation: s)
        c.logLevel = .error
        return c
    }()
    static var event: Event = {
        let details = ServerlessLogger.Event.JSBLogDetails(level: .error,
                                                           date: Date(),
                                                           message: "EndToEndMock1EventMessage",
                                                           functionName: "EndToEndMock1FunctionName",
                                                           fileName: "EndToEndMock1FileName",
                                                           lineNumber: 1000)
        let event = ServerlessLogger.Event(incident: "EndToEndMock1Incident",
                                           logDetails: details,
                                           errorDetails: nil,
                                           extraDetails: nil)
        return event
    }()
}

