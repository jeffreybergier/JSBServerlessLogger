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

/// Untested code on macOS
internal let IS_SANDBOXED: Bool = {
    #if !os(macOS)
    return true
    #else
    // Refer to this to see how I got this code
    // https://stackoverflow.com/questions/12177948/how-do-i-detect-if-my-app-is-sandboxed/47105177#comment71759807_42244464
    // https://eclecticlight.co/2019/05/11/checking-your-apps-own-signature/
    var staticCode: SecStaticCode!
    let bundleURL = Bundle.main.bundleURL
    guard SecStaticCodeCreateWithPath(bundleURL as CFURL, [], &staticCode) != 0 else {
        return false
    }
    guard staticCode != nil else {
        return false
    }
    guard SecStaticCodeCheckValidityWithErrors(staticCode,
                                               SecCSFlags(rawValue: kSecCSBasicValidateOnly),
                                               nil,
                                               nil) != 0
    else {
        return false
    }
    var sandboxRequirement: SecRequirement?
    guard SecRequirementCreateWithString("entitlement[\"com.apple.security.app-sandbox\"] exists" as CFString,
                                         [],
                                         &sandboxRequirement) == errSecSuccess
    else {
        return false
    }
    let codeCheckResult: OSStatus = SecStaticCodeCheckValidityWithErrors(staticCode,
                                                                         SecCSFlags(rawValue: kSecCSBasicValidateOnly),
                                                                         sandboxRequirement,
                                                                         nil)
    guard codeCheckResult == errSecSuccess else {
        return false
    }
    return true
    #endif
}()
