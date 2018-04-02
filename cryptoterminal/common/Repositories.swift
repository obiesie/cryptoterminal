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
    
    weak var delegate:BalancePersistenceDelegate? { get set }
    
    func addBalance(balances : [Balance])
    func allBalances() -> [Balance]
}
