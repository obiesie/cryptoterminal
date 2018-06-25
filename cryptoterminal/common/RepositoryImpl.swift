//
//  RepositoryImpl.swift
//  cryptoterminal
//
import GRDB
import Foundation

struct SQLiteRepository: CurrencyPairRepo, ExchangeRateRepo, BalanceRepo, WalletRepo, PositionRepo {
   
    weak var delegate : BalancePersistenceDelegate?
    weak var walletDelegate : WalletPersistenceDelegate?
    weak var positionDelegate: PositionPersistenceDelegeate?

    var db: DatabaseQueue?
    
    init(db:DatabaseQueue? = Datasource.shared.db){
        self.db = db
    }
    
    func addBalance(balances: [Balance]) {
        for balance in balances {
            if let _exchangeId = balance.exchangeId {
                try? db?.inTransaction{db in
                    let deleteSql = "DELETE FROM BALANCE WHERE CURRENCY = \(balance.currencyId) AND EXCHANGE = \(_exchangeId);"
                    try db.execute(deleteSql)
                    try balance.save(db)
                    return .commit
                }
            } else if let _walletId = balance.walletId {
                try? db?.inTransaction{ db in
                    let deleteSql = "DELETE FROM BALANCE WHERE CURRENCY = \(balance.currencyId) AND WALLET_ADDRESS = \(_walletId);"
                    try db.execute(deleteSql)
                    try balance.save(db)
                    return .commit
                }
            }
        }
        delegate?.addedBalance(sender: self)
    }
    
    func allBalances() -> [Balance] {
        return try! db!.inDatabase{
            db in try Balance.fetchAll(db)
        }
    }
    
    func watchListedCurrencyPairs() -> [CurrencyPair] {
        return CurrencyPair.watchListedPairs()
    }
    
    func allCurrencyPairs() -> [CurrencyPair] {
        return CurrencyPair.allCurrencyPairs()
    }
    
    func updateCurrencyPair(pair: CurrencyPair) {
        CurrencyPair.update(pair: pair)
    }
    
    func exchangeRates(for pair: CurrencyPair) -> [HistoricalExchangeRate] {
        return pair.historicalRates()
    }
    
    func exchangeRates(for pair: CurrencyPair, after cutoff: TimeInterval) -> [HistoricalExchangeRate] {
        return pair.historicalRates(after: cutoff)
    }
    
    func addWallet(cryptoAddressIdentifier: String, cryptoAddressType: Int64, addressNickname: String) {
        let wallet = Wallet.addWallet( cryptoAddressIdentifier: cryptoAddressIdentifier,
                          cryptoAddressType: cryptoAddressType,
                          addressNickname: addressNickname)
        
        walletDelegate?.addedWallet(sender: self, wallet: wallet)
    }
    
    func deleteWallet(withId walletId: Int) {
        Wallet.deleteWallet(withId: walletId)
        walletDelegate?.deletedWallet(sender: self, walletId:walletId)
    }
    
    func addPosition(position:Position) {
        try! db?.inDatabase{ db in try position.save(db)}
        positionDelegate?.positionAdded(sender: self, position: position)
    }
    
    func removePosition(position:Position) {
        _ = try! db?.inDatabase{ db in try Position.deleteOne(db, key: position.id) }
        positionDelegate?.positionRemoved(sender: self, position: position)
    }
    
    func allPositions() -> [Position]{
        return Position.allPositions()
    }
}



protocol BalancePersistenceDelegate: class {
    func addedBalance(sender: BalanceRepo)
}

protocol WalletPersistenceDelegate: class {
    func addedWallet(sender: WalletRepo, wallet: Wallet)
    func deletedWallet(sender: WalletRepo, walletId: Int)
}

protocol PositionPersistenceDelegeate: class {
    func positionAdded(sender: PositionRepo, position: Position)
    func positionRemoved(sender: PositionRepo, position: Position)
}
