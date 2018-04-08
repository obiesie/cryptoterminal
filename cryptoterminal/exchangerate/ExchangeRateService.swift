//
//  PriceService.swift
//  cryptoterminal
//


import Foundation

final class SpotExchangeRateService : NSObject {
    
    let priceApi = "https://min-api.cryptocompare.com/data/price?"
    let fromQueryParam = "fsym"
    let toQueryParam = "tsyms"
    let defaultLocaleCode = "en_US"
    let opQueue = CryptoOperationQueue()
    
    static let shared : SpotExchangeRateService =  {
        let instance = SpotExchangeRateService()
        return instance
    }()
    
    //MARK: Init
    override init() {
        super.init()
    }
    
    func startService(){
        Timer.scheduledTimer(timeInterval: 60.0, target: SpotExchangeRateService.shared,
                             selector: #selector(SpotExchangeRateService.updatePrices as (SpotExchangeRateService) -> (Bool) -> ()), userInfo: nil, repeats: true)
    }
    
    func priceFor(crypto: String) -> Double?{
        return nil
    }
    
    @objc func updatePrices(generatePriceUpdateNotification : Bool = true){
        
        let opQueue = CryptoOperationQueue()
        let downloadOp = GetSpotExchangeRateService(opResult: OperationResultContext())
        
        opQueue.isSuspended = false
        opQueue.addOperation(downloadOp)
        
    }
}


class GetSpotExchangeRateService: GroupOperation {
    static let priceApi = "https://min-api.cryptocompare.com/data/price?"
    static let fromQueryParam = "fsym"
    static let toQueryParam = "tsyms"
    static let defaultLocaleCode = "en_US"
    let opResult: OperationResultContext
    
    init(opResult: OperationResultContext){
        self.opResult = opResult
        super.init(operations: GetSpotExchangeRateService.createOps())
    }
    
    static func createOps(generatePriceUpdateNotification : Bool = true) -> [CryptoOperation]{
        guard let urlComponents = NSURLComponents(string: priceApi) else { return [] }
        let currencyPairs = CurrencyPair.allCurrencyPairs()
        let notificationOperation = NotificationOperation(notification:CryptoNotification.cryptoUpdatedNotification)
        let pairsByBaseCurrency = Dictionary(grouping : currencyPairs, by: {(val: CurrencyPair) in return val.baseCurrency})
        
        var ops = [CryptoOperation]()
        for (baseCurrency, pairs) in pairsByBaseCurrency {
            let denominatedCurrencies =  pairs.map{ $0.denominatedCurrency }
            let queryItems = [URLQueryItem(name: fromQueryParam, value: baseCurrency.code),
                              URLQueryItem(name: toQueryParam, value: denominatedCurrencies.map{$0.code}.joined(separator: ",") )]
            urlComponents.queryItems = queryItems
            guard let url = urlComponents.url else {return [] }
            
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard error == nil, let responseData = data else { NSLog((error?.localizedDescription)!); return}
                
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
            }
            let op = URLSessionTaskOperation(task: task)
            notificationOperation.addDependency(op)
            ops.append(op)
        }
        ops.append(notificationOperation)
        return ops
    }
}


