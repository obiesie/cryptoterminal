//
//  CryptoExchange.swift
//  cryptoterminal
//

import GRDB
import Foundation

class CryptoExchange : NSObject, RowConvertible, TableMapping, Persistable {
    
    static var databaseTableName: String {
        return "EXCHANGE"
    }
    var id : Int
    @objc let name : String
    let api : String
    
    enum Columns {
        static let ID = Column("ID")
        static let NAME = Column("NAME")
        static let API = Column("API")
    }
    
    required init(row: Row) {
        id = row["ID"]
        name = row["NAME"]
        api = row["API"]
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["ID"] = id
        container["NAME"] = name
        container["ENDPOINT"] = api
    }
    
    static func exchangeWithName(_ name: String) -> CryptoExchange? {
        var cryptoExchange : CryptoExchange?
        Datasource.shared.db?.inDatabase{db in
            cryptoExchange = try! CryptoExchange.filter(Columns.NAME == name).fetchOne(db)
        }
        return cryptoExchange
    }
    
    static func allCryptoExchanges() -> [CryptoExchange] {
        var cryptoExchanges = [CryptoExchange]()
        Datasource.shared.db?.inDatabase{db in
            cryptoExchanges = try! CryptoExchange.fetchAll(db)
        }
        return cryptoExchanges
    }
}

