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

#if canImport(UIKit)
import UIKit

extension Event {
    public struct DeviceDetails: Codable {
        public let identifierForVendor = UIDevice.current.identifierForVendor
        public let systemVersion       = UIDevice.current.systemVersion
        public let systenName          = UIDevice.current.systemName
        public let model               = UIDevice.current.model
        public let localizedModel      = UIDevice.current.localizedModel
        public let batteryLevel        = UIDevice.current.batteryLevel
        public let batteryState        = UIDevice.current.batteryState.stringValue
        public let storageRemaining: Int
        public let storageTotal: Int
        public let memoryFree:  Int
        public let memoryUsed:  Int
        public let memoryTotal: Int
        public init() {
            let disk = diskResourceValues
            self.storageRemaining = (disk?.volumeAvailableCapacity ?? -1000000) / 1000000
            self.storageTotal = (disk?.volumeTotalCapacity ?? -1000000) / 1000000
            let memory = vmMemoryCount
            self.memoryFree  = memory?.free  ?? -1
            self.memoryUsed  = memory?.used  ?? -1
            self.memoryTotal = memory?.total ?? -1
        }
    }
}

extension UIDevice.BatteryState {
    public var stringValue: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .unplugged:
            return "Unplugged"
        case .charging:
            return "Charging"
        case .full:
            return "Full"
        @unknown default:
            return "@unknown default"
        }
    }
}

#else

extension Event {
    public struct DeviceDetails: Codable {
        
        public var storageRemaining: Int
        public var storageTotal: Int
        public var memoryFree:  Int
        public var memoryUsed:  Int
        public var memoryTotal: Int
        
        public init() {
            let disk = diskResourceValues
            self.storageRemaining = (disk?.volumeAvailableCapacity ?? -1000000) / 1000000
            self.storageTotal = (disk?.volumeTotalCapacity ?? -1000000) / 1000000
            let memory = vmMemoryCount
            self.memoryFree  = memory?.free  ?? -1
            self.memoryUsed  = memory?.used  ?? -1
            self.memoryTotal = memory?.total ?? -1
        }
    }
}

#endif
