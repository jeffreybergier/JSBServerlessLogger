//
//  Created by Jeffrey Bergier on 2020/09/27.
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

extension Foundation.FileManager {
    /// Iterates through every file and subfolder to get the total bytes
    /// returns: Size in bytes
    internal func size(folder: URL) throws -> Int {
        let properties: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        guard let enumerator = self.enumerator(at: folder, includingPropertiesForKeys: Array(properties)) else {
            throw NSError() // provided URL was probably a file or doesn't exist
        }
        var size: Int = 0
        var next: URL?
        let progress = {
            next = enumerator.nextObject() as! URL?
        }
        progress()
        guard next != nil else {
            throw NSError() // provided URL was probably a file or doesn't exist
        }
        while next != nil {
            defer { progress() }
            let resources = try next!.resourceValues(forKeys: properties)
            let totalFileAllocatedSize = resources.totalFileAllocatedSize ?? 0
            size += totalFileAllocatedSize
        }
        return size
    }
}
