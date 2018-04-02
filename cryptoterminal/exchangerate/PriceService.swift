//
//  PriceService.swift
//  cryptoterminal
//


import Foundation

final class PriceService : NSObject {
    
    let priceApi = "https://min-api.cryptocompare.com/data/price?"
    let fromQueryParam = "fsym"
    let toQueryParam = "tsyms"
    let defaultLocaleCode = "en_US"
    let pendingOperations = OperationQueue()
    
    
    static let shared : PriceService =  {
        let instance = PriceService()
        return instance
    }()
    
    //MARK: Init
    override init() {
        super.init()
    }
    
    func startService(){
        Timer.scheduledTimer(timeInterval: 60.0, target: PriceService.shared,
                             selector: #selector(PriceService.updatePrices as (PriceService) -> (Bool) -> ()), userInfo: nil, repeats: true)
    }
    
    func priceFor(crypto: String) -> Double?{
        return nil
    }
    
    @objc func updatePrices(generatePriceUpdateNotification : Bool = true){
        guard let urlComponents = NSURLComponents(string: priceApi) else { return }
        let currencyPairs = CurrencyPair.allCurrencyPairs()
        let notificationOperation = NotificationOperation(notification:CryptoNotification.cryptoUpdatedNotification)
        let pairsByBaseCurrency = Dictionary(grouping : currencyPairs, by: {(val: CurrencyPair) in return val.baseCurrency})

        let downloadGroup = DispatchGroup()

        for (baseCurrency, pairs) in pairsByBaseCurrency {
            let denominatedCurrencies =  pairs.map{ $0.denominatedCurrency }
            let queryItems = [URLQueryItem(name: fromQueryParam, value: baseCurrency.code),
                              URLQueryItem(name: toQueryParam, value: denominatedCurrencies.map{$0.code}.joined(separator: ",") )]
            urlComponents.queryItems = queryItems
            guard let url = urlComponents.url else {return}
            
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard error == nil, let responseData = data else { NSLog((error?.localizedDescription)!); downloadGroup.leave(); return}
                
                if let json = try! JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: Any]{
                    try! Datasource.shared.db?.inTransaction{ db in
                        let updateSQL = "UPDATE CURRENCY_PAIR SET SPOT_RATE = :spotPrice WHERE BASE_CURRENCY = :baseCurrency AND DENOMINATED_CURRENCY = :denominatedCurrency"
                        let updateStatement = try db.makeUpdateStatement(updateSQL)
                        for denominatedCurrency in denominatedCurrencies {
                            if let exchangeRate = json[denominatedCurrency.code] as? Double {
                                updateStatement.unsafeSetArguments([exchangeRate, baseCurrency.id, denominatedCurrency.id])
                                try! updateStatement.execute()
                            }
                        }
                        return .commit
                    }
                }
                downloadGroup.leave()
            }
            downloadGroup.enter()
            task.resume()
        }
        downloadGroup.wait()
        pendingOperations.addOperation(notificationOperation)
    }
}
