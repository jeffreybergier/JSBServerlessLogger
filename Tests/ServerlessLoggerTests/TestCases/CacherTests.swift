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

class CacherTests: AsyncTestCase {

    func test_lazyLoad() {
        var alreadyFetchedValue = false
        let lhs = 5
        let wait = self.newWait()
        let cache = Cacher(timeout: 10) { () -> Int in
            wait() { XCTAssertTrue(alreadyFetchedValue) }
            return lhs
        }
        self.do(after: .short) {
            alreadyFetchedValue = true
            let rhs = cache.value
            XCTAssertEqual(lhs, rhs)
        }
        self.wait(for: .medium)
    }

    func test_cacheNotExpired() {
        let expectedValue = 5
        let wait = self.newWait(count: 1)
        let cache = Cacher(timeout: 10) { () -> Int in
            wait(nil)
            return expectedValue
        }
        XCTAssertEqual(cache.value, expectedValue)
        self.do(after: .short) {
            XCTAssertEqual(cache.value, expectedValue)
        }
        self.do(after: .medium) {
            XCTAssertEqual(cache.value, expectedValue)
        }
        self.wait(for: .long)
    }

    func test_cacheExpired() {
        let expectedValue = 5
        let wait = self.newWait(count: 2)
        let cache = Cacher(timeout: Delay.short.rawValue) { () -> Int in
            wait(nil)
            return expectedValue
        }
        XCTAssertEqual(cache.value, expectedValue) // trigger generator
        self.do(after: .instant) {
            XCTAssertEqual(cache.value, expectedValue) // do not trigger generator
        }
        self.do(after: .medium) {
            XCTAssertEqual(cache.value, expectedValue) // trigger generator
        }
        self.wait(for: .long)
    }

}
