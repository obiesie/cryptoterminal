//
//  HistoricalPriceService.swift
//  cryptoterminal
//

import os
import GRDB
import SwiftDate
import Foundation


class HistoricalPriceService: NSObject {
    
    static let shared : HistoricalPriceService =  {
        let instance = HistoricalPriceService()
        return instance
    }()
    
    func startService(){
        Timer.scheduledTimer(timeInterval: 60, target: HistoricalPriceService.shared,
                             selector: #selector(fetchHistoricalPrices),
                             userInfo: nil, repeats: true)
    }
    
    @objc func fetchHistoricalPrices() {
        let opQueue = CryptoOperationQueue()
        let downloadOp = GetHistoricalPriceService(opResult: OperationResultContext())
        
        opQueue.isSuspended = false
        opQueue.addOperation(downloadOp)
    }
}



class GetHistoricalPriceService : GroupOperation {
    let opResult : OperationResultContext
    
    init(opResult: OperationResultContext){
        self.opResult = opResult
        var ops = [Operation]()
        let parseOp = HistoricalPriceParser( apiResult:self.opResult )
        let currencyPairs = CurrencyPair.allCurrencyPairs().filter{$0.watchListed}
        for pair in currencyPairs {
            let downloadOp = CryptoHistoricalPriceTask(downloadedDataContainer:self.opResult, currencyPair: pair)
            parseOp.addDependency(downloadOp)
            ops.append(downloadOp)
        }
        ops.append(parseOp)
        super.init(operations: ops)
    }
}


class HistoricalPriceParser : CryptoOperation {
    
    let apiResult : OperationResultContext
    
    init( apiResult : OperationResultContext){
        self.apiResult = apiResult
    }
    
    override func execute(){
        
        try! Datasource.shared.db?.inTransaction{db in
            let insertSQL = "INSERT INTO HISTORICAL_EXCHANGE_RATE (time, open, high, close, low, currency_pair) VALUES(:time, :open, :high, :close, :low, :currency_pair)"
            let statement = try db.makeUpdateStatement(insertSQL)
            
            for historicalPrice in apiResult.data {
                statement.unsafeSetArguments([historicalPrice["time"] as! Double, historicalPrice["open"] as! Double,
                                              historicalPrice["high"] as! Double, historicalPrice["close"] as! Double,
                                              historicalPrice["low"] as! Double, historicalPrice["currencyPairId"] as! Int])
                try! statement.execute()
            }
            return .commit
        }
        self.finish(errors: [])
        NotificationCenter.default.post(name: Notification.Name(CryptoNotification.hisoricalPriceUpdateNotification), object: nil)
        os_log("Updated historical data", log: OSLog.default, type: .default)
        
    }
}

class CryptoHistoricalPriceTask: CryptoOperation {
    var volToDownload = 1999.0
    let currencyPair:CurrencyPair
    let pendingOperations = OperationQueue()
    let downloadedDataContainer : OperationResultContext
    let downloadGroup = DispatchGroup()
    
    init( downloadedDataContainer : OperationResultContext, currencyPair : CurrencyPair) {
        self.currencyPair = currencyPair
        self.downloadedDataContainer = downloadedDataContainer
    }
    
    override func execute(){
        
        // Oldest historical price timestamp that should be in database
        let oldest = Int((DateInRegion() - 7.days).absoluteDate.timeIntervalSince1970)
        
        try! Datasource.shared.db?.inTransaction{db in
            let deleteSql = "DELETE FROM HISTORICAL_EXCHANGE_RATE WHERE CURRENCY_PAIR = \(currencyPair.id!) and time <= \(oldest);"
            try db.execute(deleteSql)
            return .commit
        }
        var oldestPrice : HistoricalExchangeRate?
        Datasource.shared.db?.read { db in
            oldestPrice = try! HistoricalExchangeRate.filter(HistoricalExchangeRate.Columns.CURRENCY_PAIR ==
                currencyPair.id).order(HistoricalExchangeRate.Columns.TIME.desc).fetchOne(db)
        }
        // crypto compare api supports a max download of 2000 records so we batch downloads in numberOfMinutesRequired/2000
        let batchDatesForDownload = computeDateBatchesForDownload(cutOffDate: oldestPrice?.time ?? oldest)
        let volsToDownload = diff(values:batchDatesForDownload)
        let dateVolumeTuples = zip( batchDatesForDownload[1...], volsToDownload)
        for (date, volToDownload) in dateVolumeTuples {
            date.roundAt(.minutes(1), type: .floor)
            let absDate = date.absoluteDate.timeIntervalSince1970
            
            os_log("Downloading %d batch size for %@", log: OSLog.default, type: .info, Int(volToDownload), currencyPair.code)
            let url = "https://min-api.cryptocompare.com/data/histominute?fsym=\(currencyPair.baseCurrency.code)&tsym=\(currencyPair.denominatedCurrency.code)&toTs=\(Int(absDate))&limit=\(Int(volToDownload-1))&aggregate=1&markets=CCCAGG"
            
            os_log("Querying %@ for historical data", log: OSLog.default, type: .default, url)
            let request = URLRequest(url: URL(string: url)!)
            downloadGroup.enter()
            URLSession.shared.dataTask(with:request, completionHandler : { (data, response, error) in
                guard let responseData = data,
                    let json = try! JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String: Any],
                    var values = json["Data"] as? [[String : Any]], error == nil else { return }
                for index in values.indices {
                    values[index]["currencyPairId"] = self.currencyPair.id
                }
                self.downloadedDataContainer.data = self.downloadedDataContainer.data + values
                self.downloadGroup.leave()
            }).resume()
        }
        downloadGroup.wait()
        self.finish(errors:[])
    }
    
    private func computeDateBatchesForDownload(cutOffDate : Int) ->  [DateInRegion]{
        let now = DateInRegion()
        let batchFirstDate = Date(timeIntervalSince1970: TimeInterval(cutOffDate))
        guard var batchDateTimes = DateInRegion.dates(between: DateInRegion(absoluteDate: batchFirstDate), and: now, increment: 2000.minutes),
            let last = batchDateTimes.last else { return [DateInRegion]() }
        
        if last.isAfter(date: now, orEqual: false, granularity: .minute) {
            batchDateTimes.removeLast()
        }
        if !last.isEqual(to: now) {
            batchDateTimes.append(now)
        }
        os_log("Date batches are %s", log: OSLog.default, type: .default, batchDateTimes)
        return batchDateTimes
    }
    
    func diff(values : [DateInRegion]) -> [Double]{
        var diffArray = [Double]()
        for index in 1..<values.count{
            diffArray.append( (values[index] - values[index - 1]).minutes )
        }
        return diffArray
    }
}



