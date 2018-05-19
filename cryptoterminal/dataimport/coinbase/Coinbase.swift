//
//  Coinbase.swift
//  cryptoterminal
//

import os
import Foundation


class GetCoinbaseData : GroupOperation {
    
    let apiKey : String
    let apiSecret : String
    static let exchangeName = "Coinbase"
    
    init(apiKey : String, apiSecret : String){
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        let opResult = OperationResultContext()
        let balanceRepo =  SQLiteRepository()
        
        let coinbaseAccountImportOperation = CoinbaseAccountImportOperation(apiResult: opResult,
                                                                            apiKey: apiKey, apiSecret: apiSecret)
        let coinbaseBalanceImportOperation = BalanceParseOperation(exchange: Balance.Exchange.COINBASE,
                                                                   apiResult: opResult, balanceRepo: balanceRepo )
        
        coinbaseBalanceImportOperation.addDependency(coinbaseAccountImportOperation)
        
        let ops = [coinbaseAccountImportOperation, coinbaseBalanceImportOperation]
        super.init(operations: ops)
    }
    
    
    override func operationDidFinish(operation: Operation, withErrors errors: [NSError]) {
        if !errors.isEmpty {
            self.cancel()
            self.finish(errors: errors)
        }
    }
    
    static func auth(request : inout URLRequest, withKey apiKey: String, withSecret apiSecret : String ){
        
        let timestamp = String(Int(NSDate().timeIntervalSince1970))
        var message = timestamp + request.httpMethod! + (request.url?.path)!
        if let query = request.url?.query  {
            message += "?\(query)"
        }
        let signature = message.hmac(algorithm: .SHA256, key: apiSecret)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue( signature, forHTTPHeaderField: "CB-ACCESS-SIGN")
        request.setValue(timestamp, forHTTPHeaderField: "CB-ACCESS-TIMESTAMP")
        request.setValue(apiKey, forHTTPHeaderField: "CB-ACCESS-KEY")
        request.setValue("2017-03-09" , forHTTPHeaderField: "CB-VERSION")
        request.setValue("application/json" , forHTTPHeaderField: "Content-Type")
    }
}

class CoinbaseAccountImportOperation : CryptoOperation {
    
    let baseURL : URL? = URL(string: "https://api.coinbase.com/v2/")
    let apiResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    
    init( apiResult : OperationResultContext, apiKey : String, apiSecret : String){
        self.apiResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    override func execute(){
        
        os_log("Importing account data", log: OSLog.default, type: .error)
        let queue = OperationQueue.current
        guard let url = URL(string: "accounts", relativeTo: baseURL) else { return }
        var request = URLRequest(url: url)
        GetCoinbaseData.auth(request: &request, withKey: self.apiKey, withSecret: apiSecret)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData, response, error) in
            var errors = [NSError]()
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                let data = responseData,
                error == nil
                else {
                    let badResponseCodes : Set = [404]
                    if let httpResponse = response as? HTTPURLResponse, badResponseCodes.contains(httpResponse.statusCode)  {
                        os_log("Could not connect to Coinbase:- %@", log: OSLog.default, type: .error, httpResponse.statusCode)
                        self.finish(errors:[ NSError(code:.ExecutionFailed,
                                                     userInfo : ["errorMessage" as NSString: "Could not connect to Coinbase server." as NSString])])
                    } else if let errorResponseData = responseData {
                        do {
                            let errorData = try JSONSerialization.jsonObject(with: errorResponseData, options: .allowFragments) as! [String:Any]
                            if let errorJson =  errorData["errors"] as? [[String:Any]], let errorInstance = errorJson.first,
                                let errorMessage = errorInstance["message"] as? String {
                                os_log("Failed to fetch data from coinbase endpoint:- %@", log: OSLog.default, type: .error, errorMessage)
                                errors.append(NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: errorMessage as NSString]))
                                self.finish(errors:errors)
                            }
                        } catch let error as NSError {
                            errors.append(error)
                            os_log("Error parsing returned error json", log: OSLog.default, type: .error, error.localizedDescription)
                        }
                    }
                    return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                if let jsonData = json["data"] as? [[String:Any]] {
                    self.apiResult.data.append(contentsOf: jsonData)
                    let coinbaseTransactionImportOperation = CoinbaseTransactionImportOperation(apiResult: self.apiResult, apiKey: self.apiKey,
                                                                                                apiSecret: self.apiSecret)
                    let parseCoinbaseTransactionOperation  = ParseImportedDataOperation(exchange:.COINBASE, apiResult: self.apiResult)
                    parseCoinbaseTransactionOperation.addDependency(coinbaseTransactionImportOperation)
                    queue?.addOperation( coinbaseTransactionImportOperation)
                    queue?.addOperation( parseCoinbaseTransactionOperation)
                }
            } catch let error as NSError {
                errors.append(error)
                os_log("Error parsing returned error json", log: OSLog.default, type: .error, error.localizedDescription)
            }
            self.finish(errors:errors)
        })
        task.resume()
    }
}



class CoinbaseTransactionImportOperation : GroupOperation {
    
    let baseURL : URL? = URL(string: "https://api.coinbase.com/v2/")
    var opResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    let pendingOperations = OperationQueue()
    
    init(apiResult : OperationResultContext, apiKey : String, apiSecret : String){
        self.opResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        let accounts = self.opResult.data
        var ops = [Operation]()
        for account in accounts {
            if let accountId = account["id"] as? String{
                let url = "v2/accounts/\(accountId)/transactions?limit=25"
                let txDownloadOp = CoinbaseAccountTransactionImportOperation(apiResult:self.opResult, apiKey:self.apiKey, apiSecret:self.apiSecret,
                                                                             transactionEndpoint: url, accountId: accountId)
                ops.append(txDownloadOp)
            }
        }
        super.init(operations: ops)
    }
}

class CoinbaseAccountTransactionImportOperation : CryptoOperation {
    let baseURL : URL? = URL(string: "https://api.coinbase.com/")
    var apiResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    let transactionEndpoint : String
    let accountId : String
    
    init(apiResult : OperationResultContext, apiKey : String, apiSecret : String,
         transactionEndpoint : String = "", accountId : String){
        self.apiResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.transactionEndpoint = transactionEndpoint
        self.accountId = accountId
    }
    
    override func execute(){
        os_log("Importing account transactions", log: OSLog.default, type: .error)
        
        let url = URL(string: transactionEndpoint, relativeTo: baseURL)
        let queue = OperationQueue.current
        
        var request = URLRequest(url: url!)
        GetCoinbaseData.auth(request: &request, withKey : self.apiKey, withSecret : self.apiSecret)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            var errors = [NSError]()
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let responseData = data, error == nil
                else {
                    let badResponseCodes : Set = [404]
                    if let httpResponse = response as? HTTPURLResponse, badResponseCodes.contains(httpResponse.statusCode)  {
                        os_log("Could not connect to Coinbase:- %@", log: OSLog.default, type: .error, httpResponse.statusCode)
                        self.finish(errors:[ NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: "Could not connect to Coinbase server." as NSString])])
                    } else if let errorResponseData = data {
                        do {
                            let errorData = try JSONSerialization.jsonObject(with: errorResponseData, options: .allowFragments) as! [String:Any]
                            if let errorJson =  errorData["errors"] as? [[String:Any]], let errorInstance = errorJson.first,
                                let errorMessage = errorInstance["message"] as? String {
                                os_log("Failed to fetch transaction data from coinbase:- %@", log: OSLog.default, type: .error, errorMessage)
                                errors.append(NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: errorMessage as NSString]))
                                self.finish(errors:errors)
                            }
                        } catch let error as NSError {
                            errors.append(error)
                            os_log("Error parsing returned error json", log: OSLog.default, type: .error, error.localizedDescription)
                        }
                    }
                    return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as! [String: Any]
                if  let jsonData = json["data"] as? [[String:Any]], let paginationData = json["pagination"] as? [String:Any],
                    let nextUrl = paginationData["next_uri"] as? String {
                    let txDownloadOp = CoinbaseAccountTransactionImportOperation(apiResult:self.apiResult, apiKey:self.apiKey, apiSecret:self.apiSecret, transactionEndpoint: nextUrl, accountId:self.accountId)
                    queue?.addOperation(txDownloadOp)
                    self.apiResult.data.append(contentsOf: jsonData )
                }
            } catch let error as NSError {
                errors.append(error)
                os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
            }
            self.finish(errors:errors)
        })
        task.resume()
    }
}


