//
//  AppDelegate.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 6/22/17.
//  Copyright © 2017 Obiesie Ike-Nwosu. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraint‌​s")
        HistoricalPriceService.shared.startService()
        SpotExchangeRateService.shared.startService()
        AddressService.shared.startService()
        DispatchQueue.main.async {
            self.updateLocalCurrencyPairs()
            self.updateCurrencyPairs()
        }
    }
    
    func updateLocalCurrencyPairs(){
        
        let allowedLocalCurrencies = ["GBP", "EUR", "USD"]
        let previousLocaleCurreny = UserDefaults.standard.value(forKey: "previousLocalCurrencyCode") as? String
        guard let currencyCode = Locale.current.currencyCode else {return}
        
        if let _previousLocaleCurreny = previousLocaleCurreny, _previousLocaleCurreny != currencyCode {
       // if let currencyCode = Locale.current.currencyCode  {
         //   if previousLocaleCurreny == nil || (previousLocaleCurreny != nil && previousLocaleCurreny! != currencyCode) {
               // if previousLocaleCurreny != currencyCode {
                    let currencyCodeToUse = allowedLocalCurrencies.contains(currencyCode) ? currencyCode : "USD"
                    let denominatedCurrency = Currency.currency(by: currencyCodeToUse)
                    let currencyPairsToDelete = CurrencyPair.allCurrencyPairs().filter{$0.watchListed == false && $0.denominatedCurrencyId != denominatedCurrency?.id}
                    currencyPairsToDelete.forEach{CurrencyPair.deleteCurrencyPair(currencyPair: $0)}
                    let cryptoCurrencies = Currency.currencies(ofType: 2)
                    let currencyPairsToAdd = cryptoCurrencies.map{ CurrencyPair.from(baseCurrency: $0, denominatedCurrency: denominatedCurrency! ) }
                    CurrencyPair.insertCurrencyPairs( currencyPairs: currencyPairsToAdd )
              //  }
           // }
        }
    }
    
    func updateCurrencyPairs(){
        
        let currencies = Currency.allCurrencies()
        let denominatedCurrencies = currencies.filter{ $0.isExchangeCurrency }
        var pairs = [CurrencyPair]()
        for denominatedCurrency in denominatedCurrencies{
            for currency in currencies{
                if denominatedCurrency.id != currency.id && currency._currencyTypeId != 1 {
                    let pair = CurrencyPair(baseCurrencyId: currency.id, denominatedCurrencyId: denominatedCurrency.id,
                                            watchListed: false, spotRate: 0.0)
                    pairs.append(pair)
                }
            }
        }
        CurrencyPair.insertCurrencyPairs(currencyPairs: pairs)
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        UserDefaults.standard.set(Locale.current.currencyCode!, forKey: "previousLocalCurrencyCode")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool{
        return true
    }
    
}

