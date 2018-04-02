//
//  CryptoAddressBalance.swift
//  cryptoterminal
//

import GRDB
import Foundation


class CryptoAddressBalance: NSObject,  RowConvertible, TableMapping, Persistable{

    static var databaseTableName: String = "CRYPTO_ADDRESS_BALANCE"
    
    var rowId : Int64?
    var cryptoId : Int64
    var cryptoAddressId : Int64
    var balance : Double
    static var addressIdColumn = Column("ADDRESS_ID")

    init(cryptoId: Int64, cryptoAddressId: Int64, balance : Double){
        self.cryptoId = cryptoId
        self.cryptoAddressId = cryptoAddressId
        self.balance = balance
        super.init()
    }
    
    required init(row: Row) {
        cryptoId = row["crypto_id"]
        cryptoAddressId = row["address_id"]
        balance = row["balance"]
        super.init()
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["crypto_id"] = cryptoId
        container["address_id"] = cryptoAddressId
        container["balance"] = balance
    }
    
    /// Update record ID after a successful insertion
    func didInsert(with rowID: Int64, for column: String?) {
        rowId = rowID
    }
    
    static func allCryptoAddressesBalances() -> [CryptoAddressBalance] {
        var cryptoAddressBalances = [CryptoAddressBalance]()
        Datasource.shared.db?.inDatabase{db in
            cryptoAddressBalances = try! CryptoAddressBalance.all().fetchAll(db)
        }
        return cryptoAddressBalances
    }
    
    static func saveCryptoBalance(cryptoAddressBalancesToSave: CryptoAddressBalance?=nil){
        Datasource.shared.db?.inDatabase{db in
            if let cryptoAddressBal = cryptoAddressBalancesToSave{
                try! cryptoAddressBal.save(db)
            }
        }
        NotificationCenter.default.post(name: Notification.Name(CryptoNotification.cryptoAddressUpdatedNotification), object: nil)
    }
}
