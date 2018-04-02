//
//  CurrencyType.swift
//  cryptoterminal
//

import GRDB
import Foundation

class CurrencyType : Record {
    
    var id : Int
    var typeName : String
    
    
    enum Columns {
        static let ID = Column("ID")
        static let TYPE = Column("TYPE")
    }
    
    override static var databaseTableName: String {
        return "CURRENCY_TYPE"
    }
    
    required init(row: Row) {
        id = row[ "ID"]
        typeName = row[ "TYPE"]
        
        super.init()
    }
    
    static func allCurrencyTypes() -> [CurrencyType]{
        var currencyTypes = [CurrencyType]()
        Datasource.shared.db?.inDatabase{db in
            currencyTypes = try! CurrencyType.all().fetchAll(db)
        }
        return currencyTypes
    }
    
    override func didInsert(with rowID: Int64, for column: String?) {
        id = Int(truncatingIfNeeded: rowID)
    }
}
