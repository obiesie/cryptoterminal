//
//  BalanceImportOperation.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 23/03/2018.
//  Copyright © 2018 Obiesie Ike-Nwosu. All rights reserved.
//

import os
import Foundation


class GetPoloniexAccountBalance: GroupOperation {
    
    // MARK: Properties
    let opResult = OperationResultContext()
    let balanceRepo = SQLiteRepository()
    let downloadOperation: Operation
    let parseOperation: Operation
    
    
    init(  apiKey: String, apiSecret: String ) {
        /*
         This operation is made of three child operations:
         1. The operation to download the JSON feed
         2. The operation to parse the JSON feed
         3. The operation to invoke the completion handler
         */
        downloadOperation = PoloniexBalanceImportOperation(apiResult: opResult, apiKey: apiKey, apiSecret: apiSecret)
        parseOperation = BalanceParseOperation(exchange: .POLONIEX, apiResult:opResult, balanceRepo: balanceRepo)
            
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        super.init(operations: [downloadOperation, parseOperation])
        
        name = "Get Poloniex Balance"
    }
    
    override func operationDidFinish(operation: Operation, withErrors errors: [NSError]) {
        if !errors.isEmpty{
            self.cancel()
            self.finish(errors: errors)
        }
    }
}

func handleBadApiResponse(data: Data?, response: URLResponse?, error: Error?, command:String, op:CryptoOperation) {
    let badResponseCodes : Set = [404]
    if let httpResponse = response as? HTTPURLResponse, badResponseCodes.contains(httpResponse.statusCode)  {
        os_log("Could not connect to poloniex:- %@", log: OSLog.default, type: .error, httpResponse.statusCode)
        op.finish(errors:[ NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: "Could not connect to Poloniex server." as NSString])])
    } else if  let responseData = data,
        let errorJson = try! JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? [String:String],
        let errorMessage =  errorJson["error"] {
        os_log("Failed to execute command: %@ on poloniex:- %@", log: OSLog.default, type: .error, command, errorMessage)
        op.finish(errors:[ NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: errorMessage as NSString])])
    }
}

class PoloniexBalanceImportOperation : CryptoOperation {
    
    let baseURL = URL(string: "https://poloniex.com/tradingApi")
    let opResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    let poloniexApiCommand = "returnCompleteBalances"
    
    init( apiResult : OperationResultContext, apiKey : String, apiSecret : String){
        self.opResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    override func execute(){
        guard let baseURL = URL(string: "https://poloniex.com/tradingApi") else {return}
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        
        // nonce value for poloniex has to be increasing so we use current time
        let nonceValue = NSDate().timeIntervalSince1970 * 1.5
        
        let queryParams = [ "command": poloniexApiCommand, "nonce": String(Int(nonceValue)) ]
        var queryItems = [URLQueryItem]()
        for (key, value) in queryParams {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        var components = URLComponents()
        components.queryItems = queryItems
        request.httpBody = components.query?.data(using: .utf8)
        GetPoloniexData.auth(request: &request, withKey: self.apiKey, withSecret: apiSecret)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                let data = responseData, error == nil,
                let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as?  [String: [String:String]]
                else {
                    handleBadApiResponse(data: responseData, response: response, error: error, command: self.poloniexApiCommand, op: self)
                    return
            }
            var balancesMap = [String:Double]()
            for (crypto, balances) in json {
                var amount = 0.0
                for (_, balance) in balances {
                    if let _balance = Double(balance){
                        amount = amount + _balance
                    }
                }
                balancesMap[crypto] = amount
            }
            self.opResult.data = [balancesMap]
            self.finish(errors: [])
        })
        task.resume()
    }
}

