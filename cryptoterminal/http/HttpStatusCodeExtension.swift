//
//  HttpStatusCodeExtension.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 26/03/2018.
//  Copyright © 2018 Obiesie Ike-Nwosu. All rights reserved.
//

import Foundation


public extension HTTPStatusCode {
    /// Informational - Request received, continuing process.
    public var isInformational: Bool {
        return isIn(range: 100...199)
    }
    /// Success - The action was successfully received, understood, and accepted.
    public var isSuccess: Bool {
        return isIn(range: 200...299)
    }
    /// Redirection - Further action must be taken in order to complete the request.
    public var isRedirection: Bool {
        return isIn(range: 300...399)
    }
    /// Client Error - The request contains bad syntax or cannot be fulfilled.
    public var isClientError: Bool {
        return isIn(range: 400...499)
    }
    /// Server Error - The server failed to fulfill an apparently valid request.
    public var isServerError: Bool {
        return isIn(range: 500...599)
    }
    
    /// - returns: `true` if the status code is in the provided range, false otherwise.
    private func isIn(range: ClosedRange<HTTPStatusCode.RawValue>) -> Bool {
        return range.contains(rawValue)
    }
}

public extension HTTPStatusCode {
    /// - returns: a localized string suitable for displaying to users that describes the specified status code.
    public var localizedReasonPhrase: String {
        return HTTPURLResponse.localizedString(forStatusCode: rawValue)
    }
}

// MARK: - Printing
extension HTTPStatusCode: CustomDebugStringConvertible, CustomStringConvertible {
    public var description: String {
        return "\(rawValue) - \(localizedReasonPhrase)"
    }
    public var debugDescription: String {
        return "HTTPStatusCode:\(description)"
    }
}

// MARK: - HTTP URL Response
public extension HTTPStatusCode {
    
    /// Obtains a possible status code from an optional HTTP URL response.
    public init?(HTTPResponse: HTTPURLResponse?) {
        guard let statusCodeValue = HTTPResponse?.statusCode else {
            return nil
        }
        self.init(statusCodeValue)
    }
    
    /// This is declared as it's not automatically picked up by the complier for the above init
    private init?(_ rawValue: Int) {
        guard let value = HTTPStatusCode(rawValue: rawValue) else {
            return nil
        }
        self = value
    }
}
