//
//  RepositoryImpl.swift
//  cryptoterminal
//


import Foundation

protocol BalancePersistenceDelegate: class {
    func addedBalance(sender: BalanceRepo)
}

struct SQLiteRepository: CurrencyPairRepo, ExchangeRateRepo, BalanceRepo {
    
    weak var delegate:BalancePersistenceDelegate?

    func addBalance(balances: [Balance]) {
        for balance in balances{
            Balance.addBalance(balance: balance)
        }
        delegate?.addedBalance(sender: self)
        NotificationCenter.default.post(name: Notification.Name(CryptoNotification.balanceUpdated), object: nil)
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
    
    
}
