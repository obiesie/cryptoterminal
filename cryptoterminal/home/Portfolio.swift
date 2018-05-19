//
//  Portfolio.swift
//  cryptoterminal
//

import GRDB
import CorePlot
import Foundation

protocol PortfolioUpdatedDelegate: class {
    func portfolioUpdated(sender: Portfolio)
}

class Portfolio : NSObject {
    
    var balanceRepo: BalanceRepo
    var assetAllocation = [String:Double]()
    weak var delegate:PortfolioUpdatedDelegate?

    var _positions = [Position]()
    var positions : [Position] {
        if _positions.isEmpty {
            _positions = positions(from : balanceRepo.allBalances())
        }
        return _positions
    }
    
    static let shared = Portfolio(balanceRepo: SQLiteRepository())
    
    var isEmpty : Bool {
        return self.positions.isEmpty
    }
    
    var assetCollection : [Currency]{
        return positions.map{ $0.baseCurrency }
    }
    
    var defaultMarketValue :  Double {
        var _defaultMarketValue = 0.0
        if let currencyCode = Locale.current.currencyCode {
            _defaultMarketValue = marketValue(in: currencyCode)
        }
        return _defaultMarketValue
    }
    
    private init(balanceRepo:BalanceRepo){
        self.balanceRepo = balanceRepo
        super.init()
        self.balanceRepo.delegate = self
        //NotificationCenter.default.addObserver(self, selector: #selector(Portfolio.balanceUpdated(notification:)), name: Notification.Name(CryptoNotification.balanceUpdated), object: nil)
    }
    
    
   /* @objc func balanceUpdated(notification: Notification){
        _positions = [Position]()
        delegate?.portfolioUpdated(sender: self)
    } */
    
    func marketValue( in currency : String) -> Double {
        let _marketValue = self.positions.reduce(0.0, {x, y in x + y.marketValue(in: currency)})
        return _marketValue
    }
    
    func positions(from balances : [Balance]) -> [Position]{
        var _positions = [Position]()
        let balancesByCrypto = Dictionary(grouping: balances, by: {$0.currencyId})
        for (cryptoId, balances) in balancesByCrypto {
            let balanceSum = balances.reduce(0, {x, y in x + y.quantity} )
            let pos = Position(itemId: Int64(cryptoId), quantity: balanceSum, purchaseDate: Date(),
                               costOfPosition : 0.0, purchaseCurrency : 0, side : "BUY", exchangeId : 0,
                               positionId :"")
            _positions.append(pos)
        }
        return _positions.sorted(by:{$0.defaultMarketValue > $1.defaultMarketValue})
    }
}

extension Portfolio : BalancePersistenceDelegate, WalletPersistenceDelegate {
    
    func deletedWallet(sender: WalletRepo, walletId: Int) {
        _positions = [Position]()
        delegate?.portfolioUpdated(sender: self)
    }
    
    func addedWallet(sender: WalletRepo, wallet:Wallet) {
        AddressService.shared.updateAddressBalances(cryptoAddresses: [wallet])
    }
    
    func addedBalance(sender: BalanceRepo) {
        _positions = [Position]()
        delegate?.portfolioUpdated(sender: self)
    }
}
