//
//  CoinbaseParseOperation.swift
//  cryptoterminal
//


import Foundation

class ParseImportedDataOperation : CryptoOperation {
    
    let apiResult : OperationResultContext
    let exchange: Exchange
    
    init(exchange: Exchange, apiResult : OperationResultContext){
        self.apiResult = apiResult
        self.exchange = exchange
    }
    
    override func execute() {
        let positions = Position.positionFrom(exchange:exchange, transactionData:self.apiResult.data)
        positions.forEach{ position in Position.addPosition(position: position) }
        self.finish(errors: [])
    }
}

class BalanceParseOperation : CryptoOperation {
    
    let apiResult : OperationResultContext
    let exchange: Balance.Exchange
    let balanceRepo : BalanceRepo
    
    init(exchange: Balance.Exchange, apiResult : OperationResultContext, balanceRepo : BalanceRepo){
        self.apiResult = apiResult
        self.exchange = exchange
        self.balanceRepo = balanceRepo
    }
    
    override func execute(){
        let balances = Balance.balanceFrom(exchange:exchange, accountData:self.apiResult.data)
        let nonzeroBalances = balances.filter{$0.quantity>0}
        balanceRepo.addBalance(balances: nonzeroBalances)
        self.apiResult.data = []
        self.finish(errors: [])
    }
}



