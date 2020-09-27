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

#if canImport(AppKit)
import AppKit

extension Event.DeviceDetails {
    public struct HardwareDetails: Codable, Equatable {

        public var systemVersion: String
        public var systemOS: String = "macOS"
        public var systemIdentifier: String

        public init() {
            let pi = ProcessInfo.processInfo
            self.systemVersion = pi.operatingSystemVersionString
            self.systemIdentifier = pi.systemIdentifier
        }
    }
}

extension ProcessInfo {
    // internal for testing only
    /// Returns the MacBook(7,1) or similar
    /// Returns -1 if there was an error fetching this
    var systemIdentifier: String {
        // Code from https://stackoverflow.com/a/25467259
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "-1" }
        var output = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &output, &size, nil, 0)
        return String(cString: output)
    }
}

#endif
