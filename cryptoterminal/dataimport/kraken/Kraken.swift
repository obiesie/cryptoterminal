//
//  KrakenDataImportOperation.swift
//  cryptoterminal
//
import os
import Foundation

class GetKrakenData : GroupOperation {
    let apiKey : String
    let apiSecret : String
    let baseURL : URL? = URL(string: "https://api.kraken.com")
    static let exchangeName = "Kraken"
    
    
    init(apiKey : String, apiSecret : String){
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        let apiResult = OperationResultContext()
        let balanceRepo = SQLiteRepository()
        
        let krakenBalanceImportOperation = KrakenBalanceImport( apiResult: apiResult, apiKey: apiKey, apiSecret: apiSecret)
        let balanceParseOperation = BalanceParseOperation(exchange: .KRAKEN, apiResult: apiResult, balanceRepo : balanceRepo)
        let krakenOrderHistoryImportOperation = KrakenOrderHistoryImportOperation( apiResult : apiResult, apiKey : apiKey, apiSecret : apiSecret)
        let parseKrakenOrderHistoryOperation  = ParseImportedDataOperation( exchange:.KRAKEN, apiResult : apiResult)
        
        balanceParseOperation.addDependency(krakenBalanceImportOperation)
        krakenOrderHistoryImportOperation.addDependency(balanceParseOperation)
        parseKrakenOrderHistoryOperation.addDependency(krakenOrderHistoryImportOperation)
        
        let ops = [krakenBalanceImportOperation, balanceParseOperation, krakenOrderHistoryImportOperation, parseKrakenOrderHistoryOperation]
        
        super.init(operations: ops )
    }
    
    static func auth(request : inout URLRequest, withKey apiKey: String, withSecret apiSecret : String ){
        guard let data = request.httpBody,
            let encodedParams = String(data: data, encoding: String.Encoding.utf8) else { return }
        let nonce = encodedParams.components(separatedBy: "=")[1]
        let shaString = (nonce + encodedParams).get_sha256_String()
        var cd = (request.url?.path)?.data(using: .utf8, allowLossyConversion: false)
        if let _shaString = shaString{
            cd?.append(_shaString)
        }
        if let _cd = cd,
            let signature = CryptoHMAC(messageData: _cd, key: apiSecret, algorithm: .SHA512)?.digest.base64EncodedString(options: []){
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue( signature, forHTTPHeaderField: "API-Sign")
            request.setValue(apiKey, forHTTPHeaderField: "API-Key")
        }
    }
    
    override func operationDidFinish(operation: Operation, withErrors errors: [NSError]) {
        if !errors.isEmpty {
            self.cancel()
            self.finish(errors: errors)
        }
    }
}


class KrakenBalanceImport : CryptoOperation {
    let baseURL : URL? = URL(string: "https://api.kraken.com/0/private/Balance")
    let apiResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    
    init( apiResult : OperationResultContext, apiKey : String, apiSecret : String){
        self.apiResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    override func execute() {
        var request = URLRequest(url: baseURL!)
        request.httpMethod = "POST"
        let params = ["nonce":String(Int(Date().timeIntervalSince1970.rounded()*1000))]
        var queryItems = [URLQueryItem]()
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        var components = URLComponents()
        components.queryItems = queryItems
        request.httpBody = components.query!.data(using: .utf8)
        GetKrakenData.auth(request: &request, withKey: self.apiKey, withSecret: apiSecret)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let responseData = data,
                let json = try! JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as?  [String:Any],
                error == nil
                else {
                    if let errorData = data,
                        let errorJson = try! JSONSerialization.jsonObject(with: errorData, options: .allowFragments) as?  [String:Any],
                        let errorArray = errorJson["error"] as? [String], let firstError = errorArray.first  {
                        os_log("Failed to fetch account balance data from kraken:- %@", log: OSLog.default, type: .error, firstError as NSString)
                        self.finish(errors:[ NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: firstError as NSString])])
                    }
                    return
            }
            if let balances = (json["result"] as? [String:Any]) {
                self.apiResult.data.append(balances)
            }
            self.finish(errors: [])
        })
        task.resume()
    }
}


class KrakenOrderHistoryImportOperation : CryptoOperation {
    
    let baseURL : URL? = URL(string: "https://api.kraken.com/0/private/TradesHistory")
    let apiResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    
    init( apiResult : OperationResultContext, apiKey : String, apiSecret : String){
        self.apiResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    override func execute() {
        self.apiResult.data = []
        var request = URLRequest(url: baseURL!)
        request.httpMethod = "POST"
        let params = ["nonce":String(Int(Date().timeIntervalSince1970.rounded()*1000))]
        var queryItems = [URLQueryItem]()
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        var components = URLComponents()
        components.queryItems = queryItems
        request.httpBody = components.query!.data(using: .utf8)
        GetKrakenData.auth(request: &request, withKey: self.apiKey, withSecret: apiSecret)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let responseData = data,
                let json = try! JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as?  [String:Any],
                let result = json["result"] as? [String:Any],
                let trades = result["trades"],
                error == nil
                else {
                    if let errorData = data,
                        let errorJson = try! JSONSerialization.jsonObject(with: errorData, options: .allowFragments) as?  [String:Any],
                        let errorArray = errorJson["error"] as? [String], let firstError = errorArray.first {
                        os_log("Failed to fetch transaction data from kraken:- %@", log: OSLog.default, type: .error, firstError)
                        self.finish(errors:[ NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: firstError as NSString])])
                    } else {
                        self.finish(errors: [NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: "Could not connect to kraken" as NSString ])])
                    }
                    return
            }
            if let tradeData = trades as? [String:[String:Any]] {
                for (_, value) in tradeData {
                    self.apiResult.data.append(value)
                }
            }
            self.finish(errors: [])
        })
        task.resume()
    }
}

