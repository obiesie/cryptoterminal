//
//  AcountService.swift
//  cryptoterminal
//

import Foundation


final class AddressService{
    
    private var accountBalances = [String : Double]()
    let pendingOperations = OperationQueue()
    
    static let shared : AddressService =  {
        let instance = AddressService()
        return instance
    }()
    
    func startService(){
        updateAddressBalances()
        Timer.scheduledTimer(timeInterval: 3600.0, target: HistoricalPriceService.shared, selector: #selector(updateAddressBalances), userInfo: nil, repeats: true)
    }
    
    
    @objc func updateAddressBalances(cryptoAddresses : [Wallet] = []){
       
        let cryptoWalletList = cryptoAddresses == [] ? Wallet.allWallets() : cryptoAddresses
        let notificationOp = NotificationOperation(notification:CryptoNotification.cryptoAddressUpdatedNotification)
        
        for cryptoWallet in cryptoWalletList{
            for crypto in cryptoWallet.cryptosForAddress() {
                if let op = createOpFor(cryptoAddress: cryptoWallet, crypto: crypto){
                    notificationOp.addDependency(op)
                    pendingOperations.addOperation(op)
                }
            }
        }
        pendingOperations.addOperation( notificationOp )
    }
    
    func createOpFor(cryptoAddress : Wallet, crypto : Currency ) -> BasicOperation? {
        guard let endPoint = crypto.balanceEndpoint?.replacingOccurrences(of: "{}", with: cryptoAddress.address),
            let url = URL(string : endPoint)
            else { return nil }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: AddressService.handleResponseFor(cryptoAddress: cryptoAddress, crypto: crypto))
        
        let taskOperation = URLSessionTaskOperation(task : task)
        return taskOperation
    }
    
    static func handleResponseFor(cryptoAddress : Wallet, crypto : Currency) -> ( (Data?, URLResponse?, Error?) -> Void) {
        
        func _handleResponse(data : Data?, response: URLResponse?, error : Error?){
            guard error == nil,
                let actualData = data                
                else { NSLog(error!.localizedDescription); return }
            do {
                if let json = try JSONSerialization.jsonObject(with: actualData, options: .allowFragments) as? [String: Any],
                   let balanceResponsePath = crypto.balanceResponsePath,
                    let balanceDecimalPlaces = crypto.balanceDecimalPlaces {
                    var innerJson = json
                    var pathIndex = 0
                    let pathTree = balanceResponsePath.components(separatedBy: ",")
                    while pathTree[pathIndex] != pathTree.last {
                        innerJson = innerJson[pathTree[pathIndex]] as! [String : Any]
                        pathIndex += 1
                    }
                    var actualbalance = 0.0
                    let decimalPlaces = Int(balanceDecimalPlaces)
                    if let balance = json[ pathTree[pathIndex]  ] as? NSString {
                        actualbalance = Double(balance.floatValue / NSDecimalNumber(decimal: pow(10, decimalPlaces)).floatValue)
                    } else if let balance = json[pathTree[pathIndex]] as? Float{
                        actualbalance = Double(balance / NSDecimalNumber(decimal: pow(10, decimalPlaces)).floatValue)
                    }
                    
                    if actualbalance > 0 {
                        let cryptoBalance = Balance(currencyId: Int(crypto.id), quantity: actualbalance,
                                walletId: cryptoAddress.id!)
                        Balance.addBalance(balance: cryptoBalance)
                    }
                }
            } catch {
                NSLog("error in JSONSerialization")
            }
        }
        return _handleResponse
    }
}

