//
//  Util.swift
//  cryptoterminal
//


import Foundation
import CorePlot


class Util{
    
    static var defaultLocaleCode = "en_GB"
    
    static func currencyCode() -> String{
        var currencyCode  = NSLocale(localeIdentifier: Util.defaultLocaleCode).currencyCode!
        NSLog("Default currency code is \(currencyCode)")
        if let userSelectedCurrency = UserDefaults().string(forKey: "currency"){
            NSLog("user selected currency is \(userSelectedCurrency)")
            let currencyString = userSelectedCurrency
            let currencyComponents = currencyString.components(separatedBy: ":")
            currencyCode = currencyComponents.last!
        }
        return currencyCode
    }
    
    static func currencyPairs(from pair: String) -> (baseCurrency:String, counterCurrency:String)? {
        var baseCurrency, counterCurrency : String
        let pairCount = pair.count
        var retVal : (String,String)?
        switch(pairCount){
        case 6: //size is 6 like XBTETH then we just split the string
            baseCurrency = String(pair[pair.startIndex ..< pair.index(pair.startIndex, offsetBy: 3)])
            counterCurrency = String(pair[pair.index(pair.startIndex, offsetBy: 3)...])
        case 7: // size is 7 pair is like XRP/XBT or XRP-XBT
            baseCurrency = String(pair[pair.startIndex ..< pair.index(pair.startIndex, offsetBy: 3)])
            counterCurrency = String(pair[pair.index(pair.startIndex, offsetBy: 4)...])
        case 8: // size is 8 like XXBTXETH
            baseCurrency = String( pair[ pair.index( after: pair.startIndex ) ..< pair.index(pair.startIndex, offsetBy: 4) ] )
            counterCurrency = String(pair[pair.index(pair.startIndex, offsetBy: 5)...])
        default:
            baseCurrency = ""
            counterCurrency = ""
        }
        if (!baseCurrency.isEmpty && !counterCurrency.isEmpty){
            retVal = (baseCurrency, counterCurrency)
        } else{
            retVal = nil
        }
        return retVal
    }
}

struct GraphConstants {
    static let PLOT_FRAME_AREA_CORNER_RADIUS : CGFloat = 1.0
    static let PLOT_FRAME_AREA_PADDING_TOP : CGFloat = 15.0
    static let PLOT_FRAME_AREA_PADDING_LEFT: CGFloat = 75.0
    static let PLOT_FRAME_AREA_PADDING_BOTTOM: CGFloat = 45.0
    static let PLOT_FRAME_AREA_PADDING_RIGHT: CGFloat = 45.0
    
    static let GRAPH_PADDING_LEFT : CGFloat = 0.0
    static let GRAPH_PADDING_RIGHT : CGFloat = 0.0
    static let GRAPH_PADDING_TOP : CGFloat = 0.0
    static let GRAPH_PADDING_BOTTOM : CGFloat = 0.0
    
    static let SCATTER_PLOT_LINE_COLOR = CPTColor(componentRed:0.06, green:0.80, blue:0.48, alpha:1.00)
    static let SCATTER_PLOT_LINE_WIDTH :CGFloat = 0.5
}

struct CSVHeaders {
    static let PAIR : String = "PAIR"
    static let PURCHASE_DATE : String = "DATE"
    static let AMOUNT : String = "VOLUME"
    static let COST : String = "COST"
    static let FEE = "FEE"
    static let SIDE = "SIDE"
    static let EXCHANGE_NAME = "EXCHANGE"
}


enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    func toCCEnum() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

enum CryptoAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    
    func hmac(algorithm: CryptoAlgorithm, key: String) -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = Int(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = algorithm.digestLength
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = Int(key.lengthOfBytes(using: String.Encoding.utf8))
        
        CCHmac(algorithm.HMACAlgorithm, keyStr, keyLen, str!, strLen, result)
        
        let digest = stringFromResult(result: result, length: digestLen)
        
        result.deallocate(capacity: digestLen)
        
        return digest
    }
    
    private func stringFromResult(result: UnsafeMutablePointer<CUnsignedChar>, length: Int) -> String {
        let hash = NSMutableString()
        for i in 0..<length {
            hash.appendFormat("%02x", result[i])
        }
        return String(hash)
    }
    
    
    // MARK: - SHA256
    func get_sha256_String() -> Data? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return digest(input: data ) //getHexString(fromData: digest(input: data ))
    }
    
    private func digest(input : Data) -> Data {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hashValue = [UInt8](repeating: 0, count: digestLength)
        input.withUnsafeBytes{
            CC_SHA256($0, UInt32(input.count), &hashValue)
        }
        return Data(bytes: hashValue, count: digestLength)
    }
    
      func getHexString(fromData data: Data) -> String {
        let bytes = [UInt8](data)
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        return hexString
    }
}


