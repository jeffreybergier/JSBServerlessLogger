//
//  Created by Jeffrey Bergier on 2020/08/13.
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
import Darwin.malloc

/// Returns size of app in memory in MB
internal var vmAppMemory: Int? {
    var stats = malloc_statistics_t()
    malloc_zone_statistics(nil, &stats)
    let size = stats.size_allocated
    guard size > 0 else { return nil }
    return size / 1000000
}

/// Returns total memory statistics in MB
internal var vmMemoryCount: (free: Int, used: Int, total: Int)? {
    // Below code is from StackOverflow by Nico
    // https://stackoverflow.com/a/8540665

    var pagesize: vm_size_t = 0

    let host_port: mach_port_t = mach_host_self()
    var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
    host_page_size(host_port, &pagesize)

    var vm_stat: vm_statistics = vm_statistics_data_t()
    var failed = false
    withUnsafeMutablePointer(to: &vm_stat) { vmStatPointer -> Void in
        vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
            if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
                NSLog("Error: Failed to fetch vm statistics")
                failed = true
            }
        }
    }
    guard !failed else { return nil }

    /* Stats in bytes */
    let mem_used = Int64(vm_stat.active_count
                         + vm_stat.inactive_count
                         + vm_stat.wire_count)
                         * Int64(pagesize)
    let mem_free = Int64(vm_stat.free_count)
                         * Int64(pagesize)
    /* Stats in MBytes */
    let mem_used_mb = Int(mem_used / 1000000)
    let mem_free_mb = Int(mem_free / 1000000)
    return (free: mem_free_mb, used: mem_used_mb, total: mem_used_mb + mem_free_mb)
}

internal var diskResourceValues: URLResourceValues? {
    let fm = FileManager.default
    let dir = IS_TESTING
        ? URL(string: "file:///")
        : fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    return try? dir?.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey])
}
