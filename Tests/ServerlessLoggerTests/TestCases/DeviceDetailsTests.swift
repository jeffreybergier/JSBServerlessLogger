//
//  DeviceDetailsTests.swift
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
@testable import ServerlessLogger

class DeviceDetailsTests: XCTestCase {

    func test_deviceDetails() {
        let lhs = Event.DeviceDetails()

        // Device details
        #if os(macOS)
        XCTAssertEqual(lhs.hardwareDetails.systemVersion, ProcessInfo.processInfo.operatingSystemVersionString)
        XCTAssertEqual(lhs.hardwareDetails.systemIdentifier, sysctl_output().components(separatedBy: " ").last!)
        XCTAssertEqual(lhs.hardwareDetails.systemOS, "macOS")
        #else
        XCTAssertEqual(lhs.hardwareDetails.identifierForVendor, UIDevice.current.identifierForVendor?.uuidString)
        XCTAssertEqual(lhs.hardwareDetails.systemVersion, UIDevice.current.systemVersion)
        XCTAssertEqual(lhs.hardwareDetails.systemOS, UIDevice.current.systemName)
        XCTAssertEqual(lhs.hardwareDetails.systemIdentifier, UIDevice.systemIdentifier)
        XCTAssertEqual(lhs.hardwareDetails.batteryLevel, UIDevice.current.batteryLevel)
        XCTAssertEqual(lhs.hardwareDetails.batteryState, UIDevice.current.batteryState.stringValue)
        #endif

        // Disk Details
        XCTAssertGreaterThan(lhs.diskDetails.diskFreeMB, 0)
        XCTAssertGreaterThan(lhs.diskDetails.diskTotalMB, 0)
        if IS_SANDBOXED {
            XCTAssertGreaterThan(lhs.diskDetails.appUsedKB, 0)
        } else {
            XCTAssertEqual(lhs.diskDetails.appUsedKB, -1)
        }

        // Memory Details
        XCTAssertGreaterThan(lhs.memoryDetails.systemFreeMB, 0)
        XCTAssertGreaterThan(lhs.memoryDetails.systemTotalMB, 0)
        XCTAssertGreaterThan(lhs.memoryDetails.appUsedKB, 0)
    }
}

#if os(macOS)
fileprivate func sysctl_output() -> String {
    let task = Process()
    task.launchPath = "/usr/sbin/sysctl"
    task.arguments = ["hw.model"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
}
#endif
