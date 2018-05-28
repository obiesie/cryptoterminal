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
    
    fileprivate let queue = DispatchQueue(label: "position", attributes: .concurrent)
    var balanceRepo: BalanceRepo
    var assetAllocation = [String:Double]()
    weak var delegate:PortfolioUpdatedDelegate?
    private var _positions = [Position]()
    
    var positions : [Position] {
        get {
            queue.sync(flags:.barrier)  { [unowned self] in
                if self._positions.isEmpty {
                    self._positions = self.positions(from : self.balanceRepo.allBalances())
                }
            }
            return queue.sync { return _positions }
        }
        
        set {
            queue.sync(flags: .barrier) { [unowned self] in
                self._positions = newValue
            }
        }
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
    
    init(balanceRepo:BalanceRepo){
        self.balanceRepo = balanceRepo
        super.init()
        self.balanceRepo.delegate = self
    }
    
    func marketValue( in currency : String) -> Double {
        let _marketValue = self.positions.reduce(0.0, {x, y in x + y.marketValue(in: currency)})
        return _marketValue
    }
    
    private func positions(from balances : [Balance]) -> [Position]{
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
        positions = [Position]()
        delegate?.portfolioUpdated(sender: self)
    }
    
    func addedWallet(sender: WalletRepo, wallet:Wallet) {
        AddressService.shared.updateAddressBalances(cryptoAddresses: [wallet])
    }
    
    func addedBalance(sender: BalanceRepo) {
        positions = [Position]()
        delegate?.portfolioUpdated(sender: self)
    }
}
