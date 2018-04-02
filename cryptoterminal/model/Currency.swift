//
//  Currency.swift
//  cryptoterminal
//


import GRDB
import Foundation

class Currency : NSObject, Codable, RowConvertible, TableMapping {
    
    var id : Int
    @objc var name : String
    @objc var code : String
    var _currencyTypeId : Int
    
    final var _addressTypeId : Int?
    final var balanceEndpoint : String?
    final var balanceResponsePath : String?
    final var balanceDecimalPlaces : Int?
    final var isExchangeCurrency : Bool
    static var historicalDayCount : Double = 7.0
    static let numberOfMinutesPerDay = 1440;
    
    var currencyType : CurrencyType {
        var type : CurrencyType?  = nil
        Datasource.shared.db?.inDatabase{ db in
            type = try! CurrencyType.filter( CurrencyType.Columns.ID == _currencyTypeId).fetchOne(db)
        }
        return type!
    }
    
    static var databaseTableName: String {
        return "CURRENCY"
    }
    
    var formatter : NumberFormatter? {
        var _formatter : NumberFormatter?
        if self.currencyType.typeName == "FIAT" {
            _formatter = CryptoFormatters.currencyFormatter
            _formatter?.currencyCode = self.code
        } else {
            _formatter = CryptoFormatters.cryptoFormatter
            _formatter?.positiveSuffix = self.code
        }
        return _formatter
    }
    
    enum Columns {
        static let ID = Column("ID")
        static let NAME = Column("NAME")
        static let CODE = Column("CODE")
        static let ADDRESS_TYPE = Column("ADDRESS_TYPE")
        static let CURRENCY_TYPE = Column("TYPE")
        
    }
    
    required init(row: Row) {
        id = row[ "ID"]
        name = row[ "NAME"]
        code = row[ "CODE"]
        _currencyTypeId = row["TYPE"]
        _addressTypeId = row["ADDRESS_TYPE"]
        balanceEndpoint = row[ "BALANCE_ENDPOINT"]
        balanceResponsePath = row[ "BALANCE_RESPONSE_PATH"]
        balanceDecimalPlaces = row[ "BALANCE_DECIMAL_PLACE"]
        isExchangeCurrency = row["IS_EXCHANGE_CURRENCY"] == 1 ? true : false
        super.init()
    }
    
    static func allCurrencies() -> [Currency]{
        var currencies = [Currency]()
        Datasource.shared.db?.inDatabase{db in
            currencies = try! Currency.fetchAll(db)
        }
        return currencies
    }
    
    static func currencies(ofType typeId: Int) -> [Currency] {
        var currencies = [Currency]()
        Datasource.shared.db?.inDatabase{ db in
            currencies = try! Currency.filter(Columns.CURRENCY_TYPE == typeId).fetchAll(db)
        }
        return currencies
    }
    
    static func currency(by currencyCode : String) -> Currency? {
        let code = currencyCode == "XBT" ? "BTC" : currencyCode
        let curr = try! Datasource.shared.db!.read { db in try Currency.filter( Columns.CODE
            == code.uppercased(with: Locale.current)).fetchOne(db) }
        return curr
    }
    
    static func currencyByName( _ name : String) -> Currency? {
        let curr = try! Datasource.shared.db!.read { db in try Currency.filter( Columns.NAME
            == name.capitalized(with: Locale.current)).fetchOne(db) }
        return curr
    }
    
    func didInsert(with rowID: Int64, for column: String?) {
        id = Int(truncatingIfNeeded: rowID)
    }
    
    static func ==(lhs: Currency, rhs: Currency) -> Bool {
        return lhs.id == rhs.id && lhs.code == rhs.code && lhs.name == rhs.name
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Currency {
            return self.id == other.id && self.code == other.code && self.name == other.name
        } else {
            return false
        }
    }
    
    override var hashValue : Int {
        get {
            return "\(id)\(code)\(name)".hashValue
        }
    }
}

