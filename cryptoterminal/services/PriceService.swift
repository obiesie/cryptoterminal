//
//  PriceService.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 6/28/17.
//  Copyright © 2017 Obiesie Ike-Nwosu. All rights reserved.
//

import Foundation

final class PriceService : NSObject {
    
    let priceApi = "https://min-api.cryptocompare.com/data/price?"
    let fromQueryParam = "fsym="
    let toQueryParam = "tsyms="
    let datasource = Datasource()
    
    
    // MARK: Shared Instance
    
    static let shared : PriceService =  {
        let instance = PriceService()
        return instance
    }()
    
    // MARK: Local Variable
    
    var cryptos : [Crypto] = []
    var cryptoPrice : [String: Double] = [:]
    
    
    //MARK: Init
    override init() {
        super.init()
        cryptos = Datasource.shared.fetchAllItems()
        for crypto in cryptos{
            cryptoPrice[crypto.name.capitalized] = crypto.price
        }
    }
    
    func fetchPrice(crypto:String) -> Double{
        return self.cryptoPrice[crypto.capitalized]!
    }
    
    func updatePrices(generatePriceUpdateNotification : Bool = true){
        print(NSLocale.current.currencyCode)
        var currencyCode = NSLocale.current.currencyCode!
        if let userSelectedCurrency = UserDefaults().string(forKey: "currency"){
            let currencyString = userSelectedCurrency
            let currencyComponents = currencyString.components(separatedBy: ":")
            currencyCode = currencyComponents.last!
        }
        for crypto in cryptos{
            let url = priceApi + fromQueryParam  + crypto.symbol + "&" + toQueryParam + currencyCode
            URLSession.shared.dataTask(with: NSURL(string: url)! as URL) { (data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                }else {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                            print(crypto.name)
                            print(json)
                            self.cryptoPrice[crypto.name.capitalized] = json[currencyCode] as? Double
                            Datasource.shared.updatePrice(coin: crypto.name, newPrice: self.cryptoPrice[crypto.name.capitalized]!)
                        }
                    } catch {
                        print("error in JSONSerialization")
                    }
                }
            }.resume()
        }
        if generatePriceUpdateNotification{
            NotificationCenter.default.post(name: Notification.Name("NotificationIdentifier1"), object: nil)
        }
    }
}


