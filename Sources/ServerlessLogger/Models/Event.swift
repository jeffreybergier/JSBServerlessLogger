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

public struct Event: Codable, Equatable {
    
    public static let kErrorKey = "JSBServerlessLoggerErrorKey"
    
    public var incident: String = String(UInt64.random(in: 10000000000000000000..<UInt64.max))
    public var logDetails: JSBLogDetails
    public var deviceDetails: DeviceDetails
    public var errorDetails: ErrorDetails?
    public var extraDetails: ExtraDetails?

    public init(incident: String? = nil,
                logDetails: JSBLogDetails,
                deviceDetails: DeviceDetails = DeviceDetails(),
                errorDetails: ErrorDetails? = nil,
                extraDetails: ExtraDetails? = nil)
    {
        if let incident = incident {
            self.incident = incident
        }
        self.logDetails = logDetails
        self.deviceDetails = deviceDetails
        self.errorDetails = errorDetails
        self.extraDetails = extraDetails
    }
}

extension Event {

    /// Extra details are added to each event. Use this to store UserID or any other useful iniformation
    public struct ExtraDetails: Codable, Equatable {
        var userID: String?
        var userInfo: [String: String]? // TODO: Replace value type with anything codable
    }
    
}

extension Event {
    public struct DeviceDetails: Codable, Equatable {

        public var hardwareDetails: HardwareDetails
        public var diskDetails: DiskDetails
        public var memoryDetails: MemoryDetails

        public init() {
            self.hardwareDetails     = .init()
            self.diskDetails         = .init()
            self.memoryDetails       = .init()
        }
    }
}

extension Event.DeviceDetails {

    public struct DiskDetails: Codable, Equatable {

        public var diskFreeMB: Int
        public var diskTotalMB: Int
        /// Size of the container for the main bundle
        /// Does not include not any app group containers
        public var appUsedKB: Int

        public init() {
            let volume = disk_rootSize
            self.diskFreeMB  = (volume?.available ?? -1000000) / 1000000
            self.diskTotalMB = (volume?.total     ?? -1000000) / 1000000
            let app = disk_appContainerSize
            self.appUsedKB   = (app ?? -1000) / 1000
        }
    }

    public struct MemoryDetails: Codable, Equatable {

        public var systemFreeMB:  Int
        public var systemTotalMB: Int
        public var appUsedKB: Int

        public init() {
            let system = memory_systemSize
            self.systemFreeMB  = (system?.free   ?? -1000000) / 1000000
            self.systemTotalMB = (system?.total  ?? -1000000) / 1000000
            let app = memory_appUsed
            self.appUsedKB     = (app ?? -1000) / 1000
        }
    }
}
