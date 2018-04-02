//
//  PoloniexDataImportOperation.swift
//  cryptoterminal
//


import Foundation

class GetPoloniexData : GroupOperation, DataImportOperation {
    
    let apiKey : String
    let apiSecret : String
    let getPoloAcctBal : Operation
    let getPoloTradeHist : Operation
    static let exchangeName = "Poloniex"
    weak var delegate: ExchangeDataImportDelegate?

    init(apiKey : String, apiSecret : String){
        self.apiKey = apiKey
        self.apiSecret = apiSecret
       
        getPoloAcctBal = GetPoloniexAccountBalance( apiKey: self.apiKey, apiSecret: self.apiSecret)
        getPoloTradeHist = GetPoloniexTradeHistory( apiKey: self.apiKey, apiSecret: self.apiSecret)
       
        getPoloTradeHist.addDependency(getPoloAcctBal)
        
        //let dataImportFinishOperation = DataImportFinishedTask()
        //dataImportFinishOperation.addDependency(getPoloTradeHist)
        //dataImportFinishOperation.delegate = delegate
        
        let ops = [getPoloAcctBal, getPoloTradeHist]
        super.init(operations: ops)
    }
    
    override func execute(){
        delegate?.exchangeDataImportStarted()
        super.execute()
    }
    
    static func auth(request : inout URLRequest, withKey apiKey: String, withSecret apiSecret : String ){
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let str = String(data: request.httpBody!, encoding: String.Encoding.utf8)!
        let messageSignature = CryptoHMAC( message: str, key: apiSecret, algorithm: .SHA512)
        request.setValue( messageSignature?.hexdigest(), forHTTPHeaderField: "Sign")
        request.setValue(apiKey, forHTTPHeaderField: "Key")
    }
    
    override func operationDidFinish(operation: Operation, withErrors errors: [NSError]) {
        if !errors.isEmpty {
            self.cancel()
            self.finish(errors: errors)
        } 
    }
}
