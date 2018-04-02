//
//  Wallet.swift
//  cryptoterminal
//


import GRDB
import Foundation

class Wallet : NSObject, RowConvertible, TableMapping, Persistable {
    
    var id : Int?
    var address : String
    var walletAlias : String?
    var addressTypeId : Int
    var addressType : CryptoAddressType? {
        var type : CryptoAddressType?
        do {
            type = try Datasource.shared.db!.read{ d in try CryptoAddressType.filter(Column("ID") == addressTypeId).fetchOne(d) }
        } catch let error {
            print(error.localizedDescription)
        }
        return type
    }
    
    init(id: Int?, typeId: Int, name: String, walletAlias : String = "") {
        self.id = id
        self.address = name
        self.walletAlias = walletAlias
        self.addressTypeId = typeId
        super.init()
    }
    
    required init(row: Row) {
        id = row["ID"]
        address = row["ADDRESS"]
        walletAlias = row["NAME"]
        addressTypeId = row["ADDRESS_TYPE"]
        super.init()
    }
    
    func didInsert(with rowID: Int64, for column: String?) {
        id = Int(rowID)
    }
    
    class var databaseTableName : String {
        return "WALLET"
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["ID"] = id
        container["ADDRESS"] = address
        container["NAME"] = walletAlias
        container["ADDRESS_TYPE"] = addressTypeId
    }
    
    static func wallet(by name : String) -> Wallet? {
        var wallet : Wallet?
        do {
            wallet = try Datasource.shared.db!.read{
                db in try Wallet.filter(Column("name") == name.uppercased(with: Locale.current)).fetchOne(db)
            }
        } catch let error {
            print(error.localizedDescription)
        }
        return wallet
    }
    
    static func allWallets() -> [Wallet]{
        var wallets = [Wallet]()
        Datasource.shared.db?.inDatabase{db in
            wallets = try! Wallet.fetchAll(db)
        }
        return wallets
    }
    
    func cryptosForAddress() -> [Currency]{
        var cryptosForAddress = [Currency]()
        Datasource.shared.db?.inDatabase{db in
            cryptosForAddress = try! Currency.filter(Currency.Columns.ADDRESS_TYPE == self.addressTypeId).fetchAll(db)
        }
        return cryptosForAddress
    }
    
    static func deleteWallet(withId walletId: Int){
        _ = try! Datasource.shared.db!.inDatabase{ db in try Wallet.deleteOne(db, key: walletId) }
    }
    
    static func addWallet(cryptoAddressIdentifier : String, cryptoAddressType : Int64,
                          addressNickname : String = "") {
        let cryptoWallet = Wallet(id:nil, typeId:Int(cryptoAddressType),
                                  name: cryptoAddressIdentifier, walletAlias: addressNickname)
        try! Datasource.shared.db?.inDatabase{ db in try cryptoWallet.insert(db)}
        AddressService.shared.updateAddressBalances(cryptoAddresses: [cryptoWallet])
    }
    
    func allCryptoBalances() -> [Balance]{
        var cryptoBalancesAtWallet = [Balance]()
        Datasource.shared.db?.inDatabase{db in
            cryptoBalancesAtWallet = try! Balance.filter(Column("wallet") == self.id).fetchAll(db)
        }
        return cryptoBalancesAtWallet
    }
}


