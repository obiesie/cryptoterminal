//
//  TradeHistoryImportOperation.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 23/03/2018.
//  Copyright © 2018 Obiesie Ike-Nwosu. All rights reserved.
//

import Foundation


class GetPoloniexTradeHistory: GroupOperation {
    
    // MARK: Properties
    let downloadOperation: PoloTradeHistoryDownloadOperation
    let parseOperation: PoloTradeHistoryParseOperation
    let opResult = OperationResultContext()

    init( apiKey: String, apiSecret: String) {
        downloadOperation = PoloTradeHistoryDownloadOperation(apiResult: opResult, apiKey: apiKey, apiSecret: apiSecret)
        parseOperation = PoloTradeHistoryParseOperation(apiResult:opResult)
        
        // These operations must be executed in order
        parseOperation.addDependency(downloadOperation)
        super.init(operations: [downloadOperation, parseOperation, ])
        
        name = "Get Poloniex"
    }
    
    override func operationDidFinish(operation: Operation, withErrors errors: [NSError]) {
        if !errors.isEmpty{
            self.cancel()
            self.finish(errors: errors)
        }
    }
}


class PoloTradeHistoryParseOperation : CryptoOperation {
    
    let apiResult : OperationResultContext
    static let exchangeName = "Poloniex"
    
    init( apiResult : OperationResultContext){
        self.apiResult = apiResult
    }
    
    override func execute(){
        let positions = Position.positionFrom(exchange: .POLONIEX, transactionData: self.apiResult.data)
        positions.forEach{ position in Position.addPosition(position: position) }
        self.finish(errors: [])
    }
}

class PoloTradeHistoryDownloadOperation : CryptoOperation {
    
    let baseURL : URL? = URL(string: "https://poloniex.com/tradingApi")
    let opResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    
    let COMMAND = "returnTradeHistory"
    let CURRENCY_PAIR = "all"
    let LIMIT = "10000"
    let START = "1225497600"
    
    init( apiResult : OperationResultContext, apiKey : String, apiSecret : String){
        self.opResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    override func execute(){
        var request = URLRequest(url: baseURL!)
        request.httpMethod = "POST"
        let endPoint = String(Int(NSDate().timeIntervalSince1970 * 1.5 ))
        let nonce = endPoint
        let params = ["currencyPair": CURRENCY_PAIR, "limit": LIMIT, "start":START, "command": COMMAND, "end": endPoint, "nonce": nonce]
        var queryItems = [URLQueryItem]()
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        var components = URLComponents()
        components.queryItems = queryItems
        request.httpBody = components.query!.data(using: .utf8)
        GetPoloniexData.auth(request: &request, withKey: self.apiKey, withSecret: apiSecret)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData, response, error) in
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200, let data = responseData,
                var json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as?  [String:[[String:Any]]] ,
                error == nil
                else {
                    handleBadApiResponse(data: responseData, response: response, error: error, command: self.COMMAND, op: self)
                    return
            }
            for index in json.indices {
                let element = json[index]
                for i in element.value.indices {
                    json[element.key]![i]["pair"] = element.key
                }
            }
            let content = json.values.reduce(into : []) { vals, val in vals.append(contentsOf: val) }
            self.opResult.data = content
            self.finish(errors: [])
        })
        task.resume()
    }
}
