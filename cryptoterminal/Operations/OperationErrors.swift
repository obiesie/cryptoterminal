//
//  OperationErrors.swift
//  cryptoterminal
//


import Foundation

let OperationErrorDomain = "OperationErrors"

enum OperationErrorCode: Int {
    case ConditionFailed = 1
    case ExecutionFailed = 2
}

extension NSError {
    convenience init(code: OperationErrorCode, userInfo: [NSObject: AnyObject]? = nil) {
        self.init(domain: OperationErrorDomain, code: code.rawValue, userInfo: (userInfo as! [String : Any]))
    }
}

// This makes it easy to compare an `NSError.code` to an `OperationErrorCode`.
func ==(lhs: Int, rhs: OperationErrorCode) -> Bool {
    return lhs == rhs.rawValue
}

func ==(lhs: OperationErrorCode, rhs: Int) -> Bool {
    return lhs.rawValue == rhs
}
