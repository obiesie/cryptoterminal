//
//  Balance.swift
//  cryptoterminal
//

import Foundation
import GRDB

class Balance : NSObject, RowConvertible, TableMapping, Persistable {
    
    var currencyId : Int
    var quantity : Double
    var walletId : Int?
    var exchangeId : Int?
    
    init(currencyId: Int, quantity: Double, walletId: Int) {
        self.quantity = quantity
        self.currencyId = currencyId
        self.walletId = walletId
        super.init()
    }
    
    init(currencyId: Int, quantity: Double, exchangeId: Int) {
        self.quantity = quantity
        self.currencyId = currencyId
        self.exchangeId = exchangeId
        super.init()
    }
    
    required init(row: Row) {
        currencyId = row["CURRENCY"]
        quantity = row["BALANCE"]
        walletId = row[ "WALLET_ADDRESS"]
        exchangeId = row["EXCHANGE"]
        super.init()
    }
    
    class var databaseTableName : String {
        return "Balance"
    }
    
    static func allBalances(db:DatabaseQueue) -> [Balance]{
        return try! db.inDatabase{
            db in try Balance.fetchAll(db)
        }
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["CURRENCY"] = currencyId
        container["BALANCE"] = quantity
        container["WALLET_ADDRESS"] = walletId
        container["EXCHANGE"] = exchangeId
    }
    
    static func balanceFrom(exchange:Exchange, accountData: [[String:Any]]) -> [Balance]{
        var positions = [Balance]()
        if let function = Exchange.parseAccountBalanceAlgorithm(exchange: exchange) {
            positions = function(accountData)
        }
        return positions
    }
    
    static func parseGdaxBalance(accounts:[[String:Any]]) -> [Balance] {
        var parsedBalances = [Balance?]()
        for account in accounts{
            if  let balanceAmountStr = account["balance"] as? String,
                let balanceAmount = Double(balanceAmountStr),
                let currencyStr = account["currency"] as? String,
                let currency = Currency.currency(by: currencyStr), currency.currencyType.id == 2,
                let exchange = CryptoExchange.exchangeWithName("COINBASE") {
                parsedBalances.append( Balance(currencyId: currency.id, quantity: balanceAmount,
                                               exchangeId: exchange.id) )
            }
        }
        return parsedBalances.compactMap{ $0 }
    }
    
    
    static func parseCoinbaseBalance( accounts : [[String:Any]] ) -> [Balance] {
        var parsedBalances = [Balance?]()
        for account in accounts{
            if let balance = account["balance"] as? [String:String],
                let balanceAmountStr = balance["amount"],
                let balanceAmount = Double(balanceAmountStr),
                let currencyStr = account["currency"] as? String,
                let currency = Currency.currency(by: currencyStr), currency.currencyType.id == 2,
                let exchange = CryptoExchange.exchangeWithName("COINBASE") {
                parsedBalances.append( Balance(currencyId: currency.id, quantity: balanceAmount,
                                               exchangeId: exchange.id) )
            }
        }
        let t = parsedBalances.compactMap{ $0 }
        // We may have multiple crypto account on coinbase so flatten these out.
        let balanceGroups = Dictionary(grouping: t, by: { $0.currencyId })
        let balances = balanceGroups.values.map({ (currencyBalances : [Balance]) -> Balance in
            var balance = 0.0
            for currencyBalance in currencyBalances {
                balance = balance + currencyBalance.quantity
            }
            let prototype = currencyBalances.first!
            return Balance(currencyId: prototype.currencyId, quantity: balance,
                           exchangeId: prototype.exchangeId!)
            
        })
        return balances
    }
    
    static func parsePoloniexBalance( balances : [[String:Any]] ) -> [Balance] {
        var parsedBalances = [Balance?]()
        if let balances = balances.first{
            for (currency, balance) in balances{
                if let instrument = Currency.currency(by: currency), instrument.currencyType.id == 2,
                    let quantity = balance as? Double,
                    let exchange = CryptoExchange.exchangeWithName("POLONIEX"){
                    parsedBalances.append( Balance(currencyId: instrument.id, quantity: quantity,
                                                   exchangeId: exchange.id) )
                }
            }
        }
        return parsedBalances.compactMap{ $0 }
    }
    
    static func parseKrakenBalance( balances : [[String:Any]] ) -> [Balance] {
        var parsedBalances = [Balance?]()
        
        if let balances = balances.first {
            for (currency, balance) in balances{
                let currencyCode = String(currency.suffix(3))
                if let instrument = Currency.currency(by: currencyCode), instrument.currencyType.id == 2,
                    let quantityString = balance as? String,
                    let quantity = Double(quantityString),
                    let exchange = CryptoExchange.exchangeWithName("KRAKEN"){
                    parsedBalances.append( Balance(currencyId: instrument.id, quantity: quantity,
                                                   exchangeId: exchange.id) )
                }
            }
        }
        return parsedBalances.compactMap{ $0 }
    }
    
    static func addBalance(balance : Balance){
        if let _exchangeId = balance.exchangeId {
            try! Datasource.shared.db?.inTransaction{db in
                let deleteSql = "DELETE FROM BALANCE WHERE CURRENCY = \(balance.currencyId) AND EXCHANGE = \(_exchangeId);"
                try db.execute(deleteSql)
                try balance.save(db)
                return .commit
            }
        } else if let _walletId = balance.walletId {
            try! Datasource.shared.db?.inTransaction{ db in
                let deleteSql = "DELETE FROM BALANCE WHERE CURRENCY = \(balance.currencyId) AND WALLET = \(_walletId);"
                try db.execute(deleteSql)
                try balance.save(db)
                return .commit
            }
        }
    }
    
    enum Exchange {
        case COINBASE, POLONIEX, GDAX, KRAKEN
        
        static func parseAccountBalanceAlgorithm(exchange: Exchange) -> (([[String:Any]]) -> [Balance])? {
            var algo :  ([[String: Any]]) -> [Balance]
            switch(exchange){
            case .COINBASE:
                algo = Balance.parseCoinbaseBalance
            case .GDAX:
                algo = Balance.parseGdaxBalance
            case .POLONIEX:
                algo = Balance.parsePoloniexBalance
            case .KRAKEN:
                algo = Balance.parseKrakenBalance
            }
            return algo
        }
    }
}

