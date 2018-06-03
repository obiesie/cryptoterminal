//
//  CryptoAddressType.swift
//  cryptoterminal
//

import GRDB
import Foundation

class CryptoAddressType: NSObject,  RowConvertible, TableMapping, Persistable{
    static var databaseTableName: String = "ADDRESS_TYPE"
    
    var id : Int64
    var name : String
    
    required init(row: Row) {
        id = row[ "id"]
        name = row[ "type"]
        super.init()
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["type"] = name
    }
    
    /// Update record ID after a successful insertion
    func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    static func allCryptoAddressType() -> [CryptoAddressType] {
        var cryptoAddressTypes = [CryptoAddressType]()
        Datasource.shared.db?.inDatabase { db in
            cryptoAddressTypes = try! CryptoAddressType.all().fetchAll(db)
        }
        return cryptoAddressTypes
    }
}
