//
//  Created by Jeffrey Bergier on 2020/09/28.
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

// TODO: Add unit tests
/// Returns sizes in bytes
internal var disk_rootSize: (available: Int, total: Int)? {
    let fm = Foundation.FileManager.default
    let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    let resources = try? dir?.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
    guard let total = resources?.volumeTotalCapacity, let available = resources?.volumeAvailableCapacity else { return nil }
    return (available: available, total: total)
}

// TODO: Add unit tests
/// Returns size in bytes.
internal var disk_appContainerSize: Int? {
    // This only works as expected if we're sandboxed
    guard IS_SANDBOXED else { return nil }
    let fm = Foundation.FileManager.default
    let _dir = fm.urls(for: .documentDirectory, in: .userDomainMask)
                 .first?
                 .deletingLastPathComponent()
    guard let dir = _dir, let size = try? fm.size(folder: dir) else { return nil }
    return size
}
