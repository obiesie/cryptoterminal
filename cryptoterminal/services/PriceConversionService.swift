//
//  PriceConversionService.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 7/15/17.
//  Copyright © 2017 Obiesie Ike-Nwosu. All rights reserved.
//

import Foundation


class PriceConversionService : NSObject {
    
    static func convertFromSourceToTarget(sourceCurrency : String, targetCurrency: String, amount : Double) -> Double{
        let sourceUnitPrice = PriceService.shared.fetchPrice(crypto: sourceCurrency)
        let targetUnitPrice = PriceService.shared.fetchPrice(crypto: targetCurrency)
        let sourceFiatPrice = amount * sourceUnitPrice
        let targetCurrencyAmount = sourceFiatPrice / targetUnitPrice
        return targetCurrencyAmount
    }
}
