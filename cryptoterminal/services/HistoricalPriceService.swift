//
//  HistoricalPriceService.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 7/17/17.
//  Copyright © 2017 Obiesie Ike-Nwosu. All rights reserved.
//

import GRDB
import SwiftDate
import Foundation


class HistoricalPriceService : NSObject{
    
    static let shared : HistoricalPriceService =  {
        let instance = HistoricalPriceService()
        return instance
    }()
    
    let itemIdColumn = Column("item_id")
    let timeColumn = Column("time")
    
    // fetch 7 day historical price for each item on watch list
    func fetchHistoricalPrices() {
        let watchListedCryptos = Datasource.shared.fetchWatchListedCryptos()
        for crypto in watchListedCryptos{
            var hist = [HistoricalPrice]()
            Datasource.shared.db?.read { db in
                hist = try! HistoricalPrice.filter(itemIdColumn==crypto.cryptoId).order(timeColumn.desc).fetchAll(db)
            }
            var latest = Int(((DateInRegion() - 7.days)+2000.minutes).absoluteDate.timeIntervalSince1970)
            if hist.count > 0{
                latest = Int(hist[0].time > latest ? hist[0].time : latest)
            }
            getHistoricalPrice(crypto: crypto, cutOff : latest)
        }
    }
    
    func updateHistoricalPrice(){
        // delete all that are older than seven days
        let now = DateInRegion()
        let historicalCutOffDate = (now - 7.days).absoluteDate.timeIntervalSince1970
        try! Datasource.shared.db?.inTransaction{db in
            try! db.execute("delete from price_history where time < ?", arguments: [historicalCutOffDate])
            return .commit
        }
        // for each crypto in watch list fetch all seven days price by minutes
        fetchHistoricalPrices()
    }
    
    
    func getHistoricalPrice(crypto : Crypto, cutOff : Int){
        
        let now = DateInRegion()
        var dateIntervals = try! DateInRegion.dates(between: DateInRegion(absoluteDate: Date(timeIntervalSince1970: TimeInterval(cutOff))), and: now, increment: 2000.minutes)
        let intervalSize = dateIntervals.count - 1
        var lastInterval = dateIntervals[intervalSize]
        if (!lastInterval.isBefore(date: now, orEqual: false, granularity: .minute)){
            dateIntervals.remove(at: intervalSize)
        }
        lastInterval = dateIntervals[dateIntervals.count - 1]
        if (!lastInterval.isEqual(to: now)){
            dateIntervals.append(now)
        }
        for (index, date) in dateIntervals.enumerated(){
            let toTs = date.absoluteDate.timeIntervalSince1970.rounded()
            let fsym = crypto.symbol
            var amountToDownload = 2000.0
            print(index, intervalSize)
            if (index == intervalSize){
                amountToDownload = (date - dateIntervals[index-1]).minutes
                print("amount to download is ", amountToDownload)
                print(date, dateIntervals[index-1])
            }
            let amount = Int(amountToDownload)
            let url = "https://min-api.cryptocompare.com/data/histominute?fsym=\(fsym)&tsym=GBP&toTs=\(toTs)&limit=\(amount)&aggregate=1&e=CCCAGG"
            URLSession.shared.dataTask(with: NSURL(string: url)! as URL) { (data, response, error) in
                if error != nil {
                    print(error!.localizedDescription)
                }else {
                    do {
                        var historicalPriceCollection = [HistoricalPrice]()
                        
                        if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                            let data = json["Data"] as? [[String : Any]]
                            historicalPriceCollection = data!.map({(p :[String:Any]) -> HistoricalPrice in return HistoricalPrice(crypto: crypto, from:p)})
                        }
                        try! Datasource.shared.db?.inTransaction{db in
                            for historicalPrice in historicalPriceCollection{
                                try! historicalPrice.insert(db)
                            }
                            return .commit
                        }
                        
                        
                    } catch {
                        print("error in JSONSerialization")
                    }
                }
                }.resume()
        }
    }
}

struct HistoricalPrice : Codable, RowConvertible, TableMapping, Persistable{
    static var databaseTableName: String = "PRICE_HISTORY"
    let cryptoId : Int64
    let close : Double
    let high : Double
    let low : Double
    let time : Int
    let open : Double
    
    init(row: Row) {
        close = row.value(named: "close")
        low = row.value(named: "low")
        high = row.value(named:"high")
        open = row.value(named:"open")
        time = row.value(named:"time")
        cryptoId = row.value(named:"item_id")
    }
    
    init(crypto: Crypto, from: [String:Any]) {
        close = from["close"] as! Double
        low = from["low"] as! Double
        high = from["high"] as! Double
        open = from["open"] as! Double
        time = from["time"] as! Int
        cryptoId = crypto.cryptoId
    }
    
    
    func encode(to container: inout PersistenceContainer) {
        container["item_id"] = cryptoId
        container["close"] = close
        container["high"] = high
        container["low"] = low
        container["time"] = time
        container["open"] = open
    }
}


