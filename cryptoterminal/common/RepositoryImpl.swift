//
//  RepositoryImpl.swift
//  cryptoterminal
//

import Foundation

protocol BalancePersistenceDelegate: class {
    func addedBalance(sender: BalanceRepo)
}

protocol WalletPersistenceDelegate: class {
    func addedWallet(sender: WalletRepo, wallet: Wallet)
    func deletedWallet(sender: WalletRepo, walletId: Int)
}

struct SQLiteRepository: CurrencyPairRepo, ExchangeRateRepo, BalanceRepo, WalletRepo {
   
    weak var delegate : BalancePersistenceDelegate?
    weak var walletDelegate : WalletPersistenceDelegate?

    func addBalance(balances: [Balance]) {
        for balance in balances{
            Balance.addBalance(balance: balance)
        }
        delegate?.addedBalance(sender: self)
    }
    
    func allBalances() -> [Balance] {
        var balances = [Balance]()
        if let db = Datasource.shared.db {
            balances.append(contentsOf: Balance.allBalances(db: db))
        }
        return balances
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
}
