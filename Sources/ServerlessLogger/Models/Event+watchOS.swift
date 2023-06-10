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

#if os(watchOS)
import WatchKit

@available(watchOS 4.0, *)
extension WKInterfaceDeviceBatteryState {
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

extension WKInterfaceDevice {
    // Internal for testing only
    /// Returns identifier in the format of `iPhone6,1` or `"-1"` if there was an error retrieving it.
    internal static let systemIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "-1" : identifier
    }()
}

extension Event.DeviceDetails {
    public struct HardwareDetails: Codable, Equatable {

        public var identifierForVendor: String
        public var appVersion: String
        public var appBuild: String
        public var systemVersion: String
        public var systemOS: String
        public var systemIdentifier: String
        public var batteryLevel: Float
        public var batteryState: String

        public init() {
            self.appVersion          = Bundle.main.version
            self.appBuild            = Bundle.main.build
            self.systemVersion       = WKInterfaceDevice.current().systemVersion
            self.systemOS            = WKInterfaceDevice.current().systemName
            self.systemIdentifier    = WKInterfaceDevice.systemIdentifier
            
            if #available(watchOS 6.2, *) {
                self.identifierForVendor = WKInterfaceDevice.current().identifierForVendor?.uuidString ?? "-1"
            } else {
                self.identifierForVendor = "-1"
            }
            
            if #available(watchOS 4.0, *) {
                self.batteryLevel        = WKInterfaceDevice.current().batteryLevel
                self.batteryState        = WKInterfaceDevice.current().batteryState.stringValue
            } else {
                self.batteryLevel = 1
                self.batteryState = "-1"
            }
        }
    }
}

#endif