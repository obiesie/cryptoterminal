//
//  Formatters.swift
//  cryptoterminal
//


import Foundation

class CryptoFormatters : NSObject{
    
    static var currencyFormatter : NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = NSLocale.current
        formatter.maximumFractionDigits = 3
        return formatter
    }
    
    static var dateFormatter : DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = NSLocale.current
        return formatter
    }
    
    static var longDateFormatter : DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = NSLocale.current
        formatter.timeStyle = .long
        return formatter
    }
    
    static var decimalFormatter : NumberFormatter{
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 3
        formatter.locale = NSLocale.current
        return formatter
    }
    
    static var percentFormatter : NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = NSLocale.current
        return formatter
    }
    
    static var cryptoFormatter : NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 6
        formatter.maximumFractionDigits = 6
        formatter.locale = NSLocale.current
        return formatter
    }
    
    static var coinbaseDateFormatter : DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
    
    static var gdaxDateFormatter : DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }
    
    static var krakenDateFormatter : DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSS"
        return dateFormatter
    }
    
    static var poloniexDateFormatter : DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }
    
    static func cryptoCurrencyFormatter(currencyCode: String) -> NumberFormatter{
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 6
        formatter.maximumFractionDigits = 6
        formatter.locale = NSLocale.current
        formatter.positiveSuffix = currencyCode
        return formatter
    }
    
    static func currencyFormatter(currencyCode: String) -> NumberFormatter{
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = currencyCode
        return currencyFormatter
    }
}


