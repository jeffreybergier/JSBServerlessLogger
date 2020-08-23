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

import XCTest
import Foundation
@testable import ServerlessLogger

class FileManagerStubParent: FileManagerProtocol {

    func moveItem(at: URL, to: URL) throws {
        fatalError()
    }

    func urls(for: Foundation.FileManager.SearchPathDirectory, in: Foundation.FileManager.SearchPathDomainMask) -> [URL] {
        fatalError()
    }

    func contentsOfDirectory(at url: URL, includingPropertiesForKeys: [URLResourceKey]?, options: Foundation.FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        fatalError()
    }

    func createDirectory(at: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) throws {
        fatalError()
    }

    func contents(atPath: String) -> Data? {
        fatalError()
    }

    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool {
        fatalError()
    }

    func fileExists(atPath: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        fatalError()
    }
}

class FileManagerClosureStub: FileManagerStubParent {
    
    var contentsAtPath: ((String) -> Data?)?

    var moveItemAtURLtoURL: ((URL, URL) throws -> Void)?

    var contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions:
        ((URL, [URLResourceKey]?, Foundation.FileManager.DirectoryEnumerationOptions) -> [URL])?

    var fileExistsAtPathIsDirectory: ((String, UnsafeMutablePointer<ObjCBool>?) -> Bool)?

    var createDirectoryAtURLWithIntermediateDirectoriesAttributes: ((URL, Bool, [FileAttributeKey : Any]?) throws -> Void)?

    var createFileAtPathWithContentsAttributes: ((String, Data?, [FileAttributeKey : Any]?) -> Bool)?

    override func contents(atPath: String) -> Data? {
        return self.contentsAtPath!(atPath)
    }

    override func moveItem(at: URL, to: URL) throws {
        try self.moveItemAtURLtoURL!(at, to)
    }

    override func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options: Foundation.FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        return self.contentsOfDirectoryAtURLIncludingPropertiesForKeysOptions!(url, keys, options)
    }

    override func fileExists(atPath: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        return self.fileExistsAtPathIsDirectory!(atPath, isDirectory)
    }

    override func createDirectory(at: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) throws {
        try self.createDirectoryAtURLWithIntermediateDirectoriesAttributes!(at, withIntermediateDirectories, attributes)
    }

    override func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool {
        return self.createFileAtPathWithContentsAttributes!(atPath, contents, attributes)
    }
}
