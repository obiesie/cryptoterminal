//
//  Crypto.swift
//  cryptoterminal
//


import Foundation


struct CryptoHMAC {
    
    private let digest : Data
    
    init?(message:String, key:String, algorithm: CryptoAlgorithm){
        guard let encodedMessage = message.data(using: .utf8), let encodedKey = key.data(using: .utf8) else { return nil }
        let digestLen = algorithm.digestLength
        let tmp = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        encodedKey.withUnsafeBytes{ encodedKeyBytes in
            encodedMessage.withUnsafeBytes{ encodedMessageBytes in
                CCHmac(algorithm.HMACAlgorithm, encodedKeyBytes, encodedKey.count, encodedMessageBytes,
                       encodedMessage.count, tmp)
            }
        }
        digest = Data(bytes: tmp, count: digestLen)
        tmp.deinitialize(count:digestLen)
    }
    
    init?(messageData: Data, key:String, algorithm:CryptoAlgorithm){
        guard let keyData = Data(base64Encoded:key) else { return nil}
        
        let digestLen = algorithm.digestLength
        let tmp = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        keyData.withUnsafeBytes{ keyDataBytes in
            messageData.withUnsafeBytes{ messageDataBytes in
                CCHmac(algorithm.HMACAlgorithm, keyDataBytes, keyData.count, messageDataBytes, messageData.count, tmp)
            }
        }
        digest = Data(bytes: tmp, count: digestLen)
        tmp.deinitialize(count:digestLen)
    }
    
    func hexdigest() -> String {
        let bytes = [UInt8](digest)
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        return hexString
    }
}
