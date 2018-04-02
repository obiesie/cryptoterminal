//
//  WatchList.swift
//  cryptoterminal
//


import GRDB
import Foundation

class CurrencyPair : NSObject, RowConvertible, TableMapping, Persistable {
    
    static var databaseTableName = "CURRENCY_PAIR"
    static var PERIOD = 7  // default max number of days that currency pair cares about for historical data
    var id: Int?
    var baseCurrencyId : Int
    var denominatedCurrencyId : Int
    var watchListed = false
    let exchange7dDelta : Double
    let exchange1dDelta : Double
    @objc let spotRate : Double
    @objc var code: String { return "\(baseCurrency.code.uppercased())/\(denominatedCurrency.code.uppercased())" }

    static let persistenceConflictPolicy = PersistenceConflictPolicy(
        insert: .ignore,
        update: .replace)
    
    var baseCurrency : Currency {
        let currency = try! Datasource.shared.db!.read{ d in try Currency.filter(Currency.Columns.ID == baseCurrencyId).fetchOne(d) }
        return currency!
    }
    
    var denominatedCurrency : Currency {
        let currency = try! Datasource.shared.db!.read{ d in try Currency.filter(Currency.Columns.ID == denominatedCurrencyId).fetchOne(d) }
        return currency!
    }
    
    init(baseCurrencyId:Int, denominatedCurrencyId:Int, watchListed:Bool, spotRate:Double){
        self.baseCurrencyId = baseCurrencyId;
        self.denominatedCurrencyId = denominatedCurrencyId
        self.watchListed = watchListed
        self.spotRate = spotRate
        self.exchange1dDelta = 0
        self.exchange7dDelta = 0
    }
    
    enum Columns {
        static let ID = Column("ID")
        static let BASE_CURRENCY = Column("BASE_CURRENCY")
        static let WATCH_LISTED = Column("WATCH_LISTED")
        static let DENOMINATED_CURRENCY = Column("DENOMINATED_CURRENCY")
        static let SPOT_PRICE = Column("SPOT_PRICE")
        static let EXCHANGE_DELTA_7D = Column("7D_EXCHANGE_DELTA")
        static let EXCHANGE_DELTA_1D = Column("1D_EXCHANGE_DELTA")
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["BASE_CURRENCY"] = baseCurrencyId
        container["DENOMINATED_CURRENCY"] = denominatedCurrencyId
        container["WATCH_LISTED"] = watchListed ? 1 : 0
        container["ID"] = id
        container["SPOT_RATE"] = spotRate
        container["7D_EXCHANGE_DELTA"] = spotRate
        container["1D_EXCHANGE_DELTA"] = spotRate

    }
    required init(row: Row){
        id = row["ID"]
        baseCurrencyId = row["BASE_CURRENCY"]
        denominatedCurrencyId = row["DENOMINATED_CURRENCY"]
        watchListed = row["WATCH_LISTED"] == "1" ? true : false
        spotRate = row["SPOT_RATE"]
        exchange1dDelta = row["1D_EXCHANGE_DELTA"]
        exchange7dDelta = row["7D_EXCHANGE_DELTA"]
    }
    
    static func from(baseCurrency:Currency, denominatedCurrency:Currency) -> CurrencyPair {
        return CurrencyPair(baseCurrencyId: baseCurrency.id, denominatedCurrencyId: denominatedCurrency.id,
                            watchListed: false, spotRate: 0)
    }
    
    static func update(pair : CurrencyPair){
        try! Datasource.shared.db?.inTransaction{d in
            try! pair.update(d, columns: [Columns.WATCH_LISTED])
            return .commit
        }
        NotificationCenter.default.post(name: Notification.Name(CryptoNotification.cryptoUpdatedNotification), object: nil)
    }
    
    func didInsert(with rowID: Int, for column: String?) {
        id = rowID
    }

    static func watchListedPairs() -> [CurrencyPair] {
        var currencyPairs = [CurrencyPair]()
        Datasource.shared.db?.inDatabase{ db in
            let selectStatement = try! db.cachedSelectStatement("SELECT * FROM CURRENCY_PAIR WHERE WATCH_LISTED = 1")
            currencyPairs = try! CurrencyPair.fetchAll(selectStatement)
        }
        return currencyPairs
    }
    
    static func allCurrencyPairs() -> [CurrencyPair]{
        var currencyPairs = [CurrencyPair]()
        Datasource.shared.db?.inDatabase{ db in
            let selectStatement = try! db.cachedSelectStatement("SELECT * FROM CURRENCY_PAIR")
            currencyPairs = try! CurrencyPair.fetchAll(selectStatement)
        }
        return currencyPairs
    }
    
    static func comprising(baseCurrencyId: Int, denominatedCurrencyId: Int) -> CurrencyPair{
        var currencyPair : CurrencyPair?
        Datasource.shared.db?.inDatabase{ db in
            let selectStatement = try! db.cachedSelectStatement("SELECT * FROM CURRENCY_PAIR WHERE base_currency=? AND denominated_currency=?")
            currencyPair = try! CurrencyPair.fetchOne(selectStatement, arguments: [baseCurrencyId, denominatedCurrencyId])
        }
        return currencyPair!
    }
    
    func exchangeRateDelta(since time:Double) -> Double {
        var newestExchangeRate, oldestExchangeRate : HistoricalExchangeRate?
        var rateDelta = 0.0
        Datasource.shared.db?.read{ db in
            newestExchangeRate = try! HistoricalExchangeRate.filter(HistoricalExchangeRate.Columns.CURRENCY_PAIR == id ).order(HistoricalExchangeRate.Columns.TIME.desc).limit(1).fetchAll(db).first
            oldestExchangeRate = try! HistoricalExchangeRate.filter(HistoricalExchangeRate.Columns.CURRENCY_PAIR == id
                && HistoricalExchangeRate.Columns.TIME > time).order(HistoricalExchangeRate.Columns.TIME.asc).limit(1).fetchAll(db).first
        }
        if let _newestExchangeRate = newestExchangeRate, let _oldestExchangeRate = oldestExchangeRate {
            rateDelta = ( _newestExchangeRate.high - _oldestExchangeRate.high ) / _oldestExchangeRate.high
        }
        return rateDelta
    }
    
    func historicalRates() -> [HistoricalExchangeRate] {
        var histPrices = [HistoricalExchangeRate]()
        Datasource.shared.db?.read{ db in
            histPrices.append(contentsOf: try! HistoricalExchangeRate.filter(HistoricalExchangeRate.Columns.CURRENCY_PAIR == id )
                .order(HistoricalExchangeRate.Columns.TIME.desc).fetchAll(db))
        }
        return histPrices
    }
    
    func historicalRates(after time:Double) -> [HistoricalExchangeRate]{
        var histPrices = [HistoricalExchangeRate]()
        Datasource.shared.db?.read{ db in
            histPrices.append(contentsOf: try! HistoricalExchangeRate.filter(HistoricalExchangeRate.Columns.CURRENCY_PAIR == id )
                .filter(HistoricalExchangeRate.Columns.TIME > time)
                .order(HistoricalExchangeRate.Columns.TIME.desc).fetchAll(db))
        }
        return histPrices
    }
    
    static func deleteCurrencyPair(currencyPair : CurrencyPair){
        try! Datasource.shared.db!.inDatabase{ db in try _ = CurrencyPair.deleteOne(db, key: ["base_Currency":currencyPair.baseCurrencyId, "denominated_Currency":currencyPair.denominatedCurrencyId]) }
    }
    
    static func saveCurrencyPairs(currencyPairs: [CurrencyPair]){
        Datasource.shared.db?.inDatabase{ db in
            for currencyPair in currencyPairs {
                    try! currencyPair.save(db)
            }
        }
    }
    
    static func insertCurrencyPairs(currencyPairs: [CurrencyPair]){
        try! Datasource.shared.db?.inTransaction{ db in
            for currencyPair in currencyPairs {
                try! currencyPair.insert(db)
            }
            return .commit
        }
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CurrencyPair {
            return self.baseCurrencyId == other.baseCurrencyId && self.denominatedCurrencyId == other.denominatedCurrencyId
        } else {
            return false
        }
    }
    
    override var hashValue : Int {
        get {
            return "\(baseCurrencyId)\(denominatedCurrencyId)".hashValue
        }
    }
}
