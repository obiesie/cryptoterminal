//
//  CurrencyPairRepository.swift
//  cryptoterminal
//

import Foundation

protocol CurrencyPairRepo {
 
    func watchListedCurrencyPairs() -> [CurrencyPair]
    func allCurrencyPairs() -> [CurrencyPair]
    func updateCurrencyPair(pair:CurrencyPair)
    
}

protocol ExchangeRateRepo {
    
    func exchangeRates(for pair: CurrencyPair) -> [HistoricalExchangeRate]
    func exchangeRates(for pair: CurrencyPair, after cutoff: TimeInterval) -> [HistoricalExchangeRate]

}

protocol BalanceRepo {
    
    var delegate:BalancePersistenceDelegate? { get set }
    
    func addBalance(balances : [Balance])
    func allBalances() -> [Balance]
}

protocol WalletRepo {
    func addWallet(cryptoAddressIdentifier: String, cryptoAddressType: Int64, addressNickname: String)
    func deleteWallet(withId walletId: Int)
}
