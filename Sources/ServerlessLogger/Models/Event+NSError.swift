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

extension Event {
    public struct ErrorDetails: Codable, Equatable {
        
        public var code: Int
        public var domain: String
        public var localizedDescription: String?
        public var localizedRecoveryOptions: [String]?
        public var localizedRecoverySuggestion: String?
        public var localizedFailureReason: String?
        public var remainingKeys: [String: String]
        
        public init(_ input: NSError) {
            // swiftlint:disable operator_usage_whitespace
            self.code = input.code
            self.domain = input.domain
            self.localizedDescription        = input.localizedDescription
            self.localizedRecoveryOptions    = input.localizedRecoveryOptions
            self.localizedRecoverySuggestion = input.localizedRecoverySuggestion
            self.localizedFailureReason      = input.localizedFailureReason
            self.remainingKeys = input.userInfo
                .filter { key, _ in
                    return key != NSLocalizedDescriptionKey
                        && key != NSLocalizedRecoveryOptionsErrorKey
                        && key != NSLocalizedRecoverySuggestionErrorKey
                        && key != NSLocalizedFailureReasonErrorKey
                }
                .mapValues { if let value = $0 as? String { return value }
                             else { return String(describing: $0) } }
            // swiftlint:enable operator_usage_whitespace
        }
    }
}
