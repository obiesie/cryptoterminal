//
//  HistoricalPrice.swift
//  cryptoterminal
//

import Foundation
import GRDB

struct HistoricalExchangeRate : Codable, RowConvertible, TableMapping, Persistable{
    static var databaseTableName: String = "HISTORICAL_EXCHANGE_RATE"
    let close : Double
    let high : Double
    let low : Double
    let time : Int
    let open : Double
    let currencyPairId: Int
    var currencyPair : CurrencyPair {
        let currency = try! Datasource.shared.db!.read{ d in try CurrencyPair.filter(CurrencyPair.Columns.ID == currencyPairId).fetchOne(d) }
        return currency!
    }    
    
    enum Columns {
        static let CLOSE = Column("CLOSE")
        static let LOW = Column("LOW")
        static let HIGH = Column("HIGH")
        static let OPEN = Column("OPEN")
        static let TIME = Column("TIME")
        static let CRYPTO_ID = Column("ITEM_ID")
        static let CURRENCY_PAIR = Column("CURRENCY_PAIR")
        
    }
    
    init(row: Row) {
        close = row["CLOSE"]
        low = row["LOW"]
        high = row["HIGH"]
        open = row["OPEN"]
        time = row["TIME"]
        currencyPairId = row["CURRENCY_PAIR"]
    }
    
    init(crypto: Currency, from: [String:Any]) {
        close = from["close"] as! Double
        low = from["low"] as! Double
        high = from["high"] as! Double
        open = from["open"] as! Double
        time = from["time"] as! Int
        currencyPairId = from["currency_pair"] as! Int
    }

    func encode(to container: inout PersistenceContainer) {
        container["CLOSE"] = close
        container["HIGH"] = high
        container["LOW"] = low
        container["TIME"] = time
        container["OPEN"] = open
        container["CURRENCY_PAIR"] = currencyPairId
    }
}
