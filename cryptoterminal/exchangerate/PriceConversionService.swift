//
//  PriceConversionService.swift
//  cryptoterminal
//


import Foundation


class PriceConversionService : NSObject {
    static let allowedFiatCurrencies =  ["EUR", "GBP", "USD"]
    static let defaultCurrencyCode = "USD"
    
    static func convertFrom(sourceCurrencySymbol: String, targetCurrencySymbol: String, amount: Double) -> (targetCryptoCurrency:Double?, fiatEquivalent:Double?){
        
        let locale = Locale.current
        let currencyCode = locale.currencyCode!
        var sourceLocaleCurrencyPair : CurrencyPair?
        var targetLocaleCurrencyPair : CurrencyPair?
        
        let localeCurrency = Currency.currency(by: allowedFiatCurrencies.contains(currencyCode) ? currencyCode : defaultCurrencyCode)
        let sourceCurrency = Currency.currencyByName(sourceCurrencySymbol)
        let targetCurrency = Currency.currencyByName(targetCurrencySymbol)
        sourceLocaleCurrencyPair = CurrencyPair.comprising(baseCurrencyId: (sourceCurrency?.id)!,
                                                           denominatedCurrencyId: (localeCurrency?.id)!)
        targetLocaleCurrencyPair = CurrencyPair.comprising(baseCurrencyId: (targetCurrency?.id)!,
                                                           denominatedCurrencyId: (localeCurrency?.id)!)
        
        let targetUnitPrice = targetLocaleCurrencyPair?.spotRate
        let sourceFiatPrice = amount * (sourceLocaleCurrencyPair?.spotRate)!
        let targetCurrencyAmount = sourceFiatPrice / targetUnitPrice!
        return (targetCurrencyAmount, sourceFiatPrice)
    }
    
}

