//
//  CryptoAddress.swift
//  cryptoterminal
//


import GRDB
import Foundation


class CryptoAddress: NSObject,  RowConvertible, TableMapping, Persistable{
    
    var addressId : Int64? = nil
    var cryptoId : Int64? = nil
    var cryptoAddress : String
    var balance : Double
    var blockChainId : Int64?
    var addressAlias : String?
    
    var addressType : CryptoAddressType? {
        let type = try! Datasource.shared.db!.read{ d in try CryptoAddressType.filter(CryptoAddress.cryptoAddressTypeColumn == blockChainId).fetchOne(d) }
        return type
    }
    
    static var cryptoIdColumn = Column("CRYPTO_ID")
    static var cryptoAddressTypeColumn = Column("BLOCKCHAIN")
    static var addressIdColumn = Column("ADDRESS_ID")

    final var  historicalPrices : [HistoricalExchangeRate] {
        let timeColumn = Column("time")
        var histPrices = [HistoricalExchangeRate]()
        Datasource.shared.db?.read{db in
            histPrices = try! HistoricalExchangeRate.filter(HistoricalExchangeRate.Columns.CRYPTO_ID == cryptoId ).order(timeColumn.desc).fetchAll(db)
        }
        return histPrices
    }
    
    init(cryptoAddress: String, balance : Double, cryptoAddressType: Int64, addressAlias : String = "") {
        self.cryptoAddress = cryptoAddress
        self.balance = balance
        self.blockChainId = cryptoAddressType
        self.addressAlias = addressAlias
        super.init()
    }
    
    static func deleteCryptoAddress(cryptoAddressId : Int64){
        try! Datasource.shared.db!.inDatabase{ db in try _ = CryptoAddress.deleteOne(db, key: cryptoAddressId) }
    }
    
    required init(row: Row) {
        cryptoAddress = row[ "Address"]
        balance = row["balance"]
        addressId = row[ "address_id"]
        blockChainId = row[ "BLOCKCHAIN"]
        addressAlias = row[ "ADDRESS_ALIAS"]
        super.init()
    }
    
    class var databaseTableName: String {
        return "CRYPTO_ADDRESS"
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["Address"] = cryptoAddress
        container["address_id"] = addressId
        container["balance"] = balance
        container["BLOCKCHAIN"] = blockChainId
        container["ADDRESS_ALIAS"] = addressAlias
    }
    
    func didInsert(with rowID: Int64, for column: String?) {
        addressId = rowID
    }
    
    static func allCryptoAddresses() -> [CryptoAddress] {
        var cryptoAddresses = [CryptoAddress]()
        Datasource.shared.db?.inDatabase{db in
            cryptoAddresses = try! CryptoAddress.fetchAll(db)
        }
        return cryptoAddresses
    }
    
    func allCryptoBalances() -> [CryptoAddressBalance]{
        var cryptoBalancesAtAddress = [CryptoAddressBalance]()
        Datasource.shared.db?.inDatabase{db in
            cryptoBalancesAtAddress = try! CryptoAddressBalance.filter(CryptoAddress.addressIdColumn == self.addressId).fetchAll(db)
        }
        return cryptoBalancesAtAddress
    }
    
    func cryptosForAddress() -> [Currency] {
        var cryptosForAddress = [Currency]()
        Datasource.shared.db?.inDatabase { db in
            cryptosForAddress = try! Currency.filter(Currency.Columns.BLOCKCHAIN == self.blockChainId).fetchAll(db)
        }
        return cryptosForAddress
    }
    
    static func persistChanges(cryptoAddressToUpdate:CryptoAddress?=nil){
        Datasource.shared.db?.inDatabase{db in
            if let cryptoAddress = cryptoAddressToUpdate {
                try! cryptoAddress.update(db)
            }
        }
        NotificationCenter.default.post(name: Notification.Name(CryptoNotification.cryptoAddressUpdatedNotification), object: nil)
    }
    
}
