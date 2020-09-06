//
//  Created by Jeffrey Bergier on 2020/08/18.
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

@objc internal protocol FileManagerProtocol {
    
    @objc(moveItemAtURL:toURL:error:)
    func moveItem(at: URL, to: URL) throws
    
    @objc(URLsForDirectory:inDomains:)
    func urls(for: Foundation.FileManager.SearchPathDirectory,
              in: Foundation.FileManager.SearchPathDomainMask) -> [URL]
    
    @objc(contentsOfDirectoryAtURL:includingPropertiesForKeys:options:error:)
    func contentsOfDirectory(at url: URL,
                             includingPropertiesForKeys: [URLResourceKey]?,
                             options: Foundation.FileManager.DirectoryEnumerationOptions) throws -> [URL]
    
    @objc(createDirectoryAtURL:withIntermediateDirectories:attributes:error:)
    func createDirectory(at: URL,
                         withIntermediateDirectories: Bool,
                         attributes: [FileAttributeKey : Any]?) throws
    
    func contents(atPath: String) -> Data?
    
    func createFile(atPath: String,
                    contents: Data?,
                    attributes: [FileAttributeKey : Any]?) -> Bool
    
    func fileExists(atPath: String,
                    isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool

    func size(of url: URL) throws -> NSNumber
}

internal enum FileManager {
    internal static var `default`: FileManagerProtocol = Foundation.FileManager.default
}

extension Foundation.FileManager: FileManagerProtocol {

    func size(of url: URL) throws -> NSNumber {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return NSNumber(value: values.fileSize!)
    }

}
