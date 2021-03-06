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
        let balanceRepo = Portfolio.shared.balanceRepo
        
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
            var errors = [NSError]()
            guard let response = response as? HTTPURLResponse, response.statusCode == 200, let responseData = data, error == nil else {
                if let errorData = data {
                    do {
                        let errorJson = try JSONSerialization.jsonObject(with: errorData, options: .allowFragments) as!  [String:Any]
                        if let errorArray = errorJson["error"] as? [String], let firstError = errorArray.first {
                            os_log("Failed to fetch account balance data from kraken:- %@", log: OSLog.default, type: .error, firstError as NSString)
                            errors.append( NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: firstError as NSString]) )
                        }
                    } catch let error as NSError {
                        errors.append(error)
                        os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
                    }
                } else {
                    errors.append( NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: "Error fetching account balance from kraken" as NSString] ) )
                    os_log("Failed to fetch account balance data from kraken - but error occurred unpacking error", log: OSLog.default, type: .error)
                }
                self.finish(errors: errors)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as!  [String:Any]
                if let balances = (json["result"] as? [String:Any]) {
                    self.apiResult.data.append(balances)
                }
            } catch let error as NSError {
                errors.append(error)
                os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
            }
            self.finish(errors: errors)
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
            var errors = [NSError]()
            guard let response = response as? HTTPURLResponse, response.statusCode == 200, let responseData = data, error == nil else {
                if let errorData = data {
                    do {
                        let errorJson = try JSONSerialization.jsonObject(with: errorData, options: .allowFragments) as!  [String:Any]
                        if let errorArray = errorJson["error"] as? [String], let firstError = errorArray.first  {
                            os_log("Failed to fetch transaction data from kraken:- %@", log: OSLog.default, type: .error, firstError)
                            self.finish(errors:[ NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: firstError as NSString])])
                        } else {
                            errors.append( NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: "Could not parse error json" as NSString]) )
                        }
                    } catch let error as NSError {
                        errors.append(error)
                        os_log("Could not parse error json", log: OSLog.default, type: .error, error.localizedDescription)
                    }
                } else {
                    errors.append( NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: "Could not connect to kraken - error unpacking error" as NSString]))
                }
                self.finish(errors: errors)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as!  [String:Any]
                if let result = json["result"] as? [String:Any], let trades = result["trades"], let tradeData = trades as? [String:[String:Any]] {
                    for (_, value) in tradeData {
                        self.apiResult.data.append(value)
                    }
                }
            } catch let error as NSError {
                errors.append(error)
                os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
            }
            self.finish(errors: errors)
        })
        task.resume()
    }
}

