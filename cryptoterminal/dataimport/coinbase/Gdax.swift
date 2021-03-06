//
//  Gdax.swift
//  cryptoterminal
//

import os
import Foundation

class GetGdaxData : GroupOperation {
    
    static let exchangeName = "GDAX"
    var accountIds = [String]()
    let baseURL : URL? = URL(string: "https://api.gdax.com")
    let apiKey : String
    let apiSecret : String
    let passphrase : String
    
    init(apiKey : String, apiSecret : String, passphrase:String){
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.passphrase = passphrase
        let opResult = OperationResultContext()
        let balanceRepo = Portfolio.shared.balanceRepo
        
        let acctImport = GDAXAccountImportOperation( apiResult : opResult, apiKey : apiKey,
                                                     apiSecret : apiSecret, passphrase:self.passphrase, opResult:opResult)
        let balanceImportOperation = BalanceParseOperation(exchange: .GDAX,
                                                           apiResult: opResult, balanceRepo: balanceRepo)
        let gdaxOrderFillImportOperation = GDAXOrderFillImportOperation( apiResult : opResult, apiKey : apiKey,
                                                                         apiSecret : apiSecret, passphrase:self.passphrase)
        let parseFillBlock = {
            let positions = Position.positionFrom(exchange:.GDAX, transactionData:opResult.data)
            positions.forEach{ position in Position.addPosition(position: position) }
        }
        
        let finishOp = BlockOperation(block: parseFillBlock)
        
        balanceImportOperation.addDependency(acctImport)
        gdaxOrderFillImportOperation.addDependency(balanceImportOperation)
        
        let ops = [acctImport, balanceImportOperation, gdaxOrderFillImportOperation]
        super.init(operations: ops, finishOperation: finishOp)
    }
    
    static func auth(request : inout URLRequest, withKey apiKey: String,
                     withSecret apiSecret : String, with passPhrase : String ){
        guard let urlPath = request.url?.path else { return }
        
        let ts = Int64(NSDate().timeIntervalSince1970)
        let timestamp = String(ts)
        var message = timestamp + request.httpMethod!.uppercased() + urlPath
        if let query = request.url?.query  {
            message += "?\(query)"
        }
        if let messageData = message.data(using: String.Encoding.utf8, allowLossyConversion: false){
            let hmac = CryptoHMAC(messageData: messageData, key: apiSecret, algorithm: .SHA256)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue( hmac?.digest.base64EncodedString(), forHTTPHeaderField: "CB-ACCESS-SIGN")
            request.setValue(timestamp, forHTTPHeaderField: "CB-ACCESS-TIMESTAMP")
            request.setValue(apiKey, forHTTPHeaderField: "CB-ACCESS-KEY")
            request.setValue("2017-03-09" , forHTTPHeaderField: "CB-VERSION")
            request.setValue("application/json" , forHTTPHeaderField: "Content-Type")
            request.setValue(passPhrase, forHTTPHeaderField: "CB-ACCESS-PASSPHRASE")
        }
    }
    
    override func operationDidFinish(operation: Operation, withErrors errors: [NSError]) {
        if !errors.isEmpty {
            self.cancel()
            self.finish(errors: errors)
        }
    }
}

class GDAXAccountImportOperation: CryptoOperation {
    static let exchangeName = "GDAX"
    let baseURL : URL? = URL(string: "https://api.gdax.com")
    let apiKey : String
    let apiSecret : String
    let passphrase : String
    let opResult: OperationResultContext
    
    init( apiResult : OperationResultContext, apiKey : String, apiSecret : String, passphrase:String, opResult:OperationResultContext){
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.passphrase = passphrase
        self.opResult = opResult
    }
    
    override func execute(){
        
        os_log("Importing account data", log: OSLog.default, type: .error)
        guard let url = URL(string: "accounts", relativeTo: baseURL) else { return }
        var request = URLRequest(url: url)
        GetGdaxData.auth(request: &request, withKey: self.apiKey, withSecret: apiSecret, with: self.passphrase)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData, response, error) in
            var errors = [NSError]()
            guard let httpResponse = response as? HTTPURLResponse, let statusCode = HTTPStatusCode(HTTPResponse: httpResponse), error == nil else {
                let errorMessage = error?.localizedDescription ?? ""
                os_log("Error while connecting to GDAX:- %@", log: OSLog.default, type: .error, errorMessage)
                self.finish(errors:[ NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: errorMessage as NSString])])
                return
            }
            if statusCode.isSuccess, let data = responseData {
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [[String: Any]]
                    os_log("Downloaded account data from gdax:- %@", log: OSLog.default, type: .info, jsonData)
                    self.opResult.data.append(contentsOf: jsonData)
                } catch let error as NSError {
                    errors.append(error)
                    os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
                }
            } else if statusCode.isClientError, let data = responseData {
                do {
                    let errorData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                    if let errorJson =  errorData["errors"] as? [[String:Any]], let errorInstance = errorJson.first,
                        let errorMessage = errorInstance["message"] as? String {
                        os_log("Client error while fetching data from gdax:- %@", log: OSLog.default, type: .error, errorMessage)
                        errors.append( NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: errorMessage as NSString]) )
                    }
                } catch let error as NSError {
                    errors.append(error)
                    os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
                }
            } else {
                os_log("Undefined error while fetching data from gdax", log: OSLog.default, type: .error)
                errors.append( NSError(code:.ExecutionFailed, userInfo: ["errorMessage" as NSString: "Error while fetching data from gdax" as NSString]))
            }
            self.finish(errors: errors)
        })
        task.resume()
    }
}

class GDAXOrderFillImportOperation : GroupOperation {
    
    let baseURL : URL? = URL(string: "https://api.gdax.com")
    var apiResult : OperationResultContext
    let apiKey : String
    let apiSecret : String
    let passphrase : String
    var after: String?
    
    init(apiResult : OperationResultContext, apiKey : String, apiSecret : String, passphrase:String, after : String? = nil){
        self.apiResult = apiResult
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.passphrase = passphrase
        self.after = after
        super.init(operations: [])
    }
    
    override func execute(){
        var urlString = "fills?limit=100"
        if let _after = after {
            urlString += "&after=" + _after
        }
        guard let url = URL(string: urlString, relativeTo: baseURL) else { return }
        var request = URLRequest(url: url)
        GetGdaxData.auth(request: &request, withKey : self.apiKey, withSecret : self.apiSecret, with: passphrase)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData, response, error) in
            var errors = [NSError]()
            guard let httpResponse = response as? HTTPURLResponse, let statusCode = HTTPStatusCode(HTTPResponse: httpResponse), error == nil else {
                let errorMessage = error?.localizedDescription ?? ""
                os_log("Error while connecting to GDAX:- %@", log: OSLog.default, type: .error, errorMessage)
                errors.append(NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: errorMessage as NSString]))
                self.finish(errors:errors)
                return
            }
            if statusCode.isSuccess, let data = responseData {
                do {
                    let fills = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [ [String: Any] ]
                    os_log("Downloaded account fill data from gdax:- %@", log: OSLog.default, type: .info, fills)
                    self.apiResult.data.append(contentsOf: fills)
                    if let cbAfter = httpResponse.allHeaderFields["cb-after"] as? String {
                        os_log("found after header so enqueuing new task - %@", log: OSLog.default, type: .info, cbAfter)
                        let op = GDAXOrderFillImportOperation(apiResult : self.apiResult, apiKey : self.apiKey,
                                                              apiSecret : self.apiSecret, passphrase:self.passphrase, after:cbAfter)
                        self.produceOperation(operation: op)
                    }
                } catch let error as NSError {
                    errors.append(error)
                    os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
                }
            } else if statusCode.isClientError, let data = responseData {
                do {
                    let errorData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
                    if let errorMessage =  errorData["message"] as? String {
                        os_log("Client error while fetching fill data from gdax:- %@", log: OSLog.default, type: .error, errorMessage)
                        errors.append(NSError(code:.ExecutionFailed, userInfo : ["errorMessage" as NSString: errorMessage as NSString]))
                    }
                } catch let error as NSError {
                    errors.append(error)
                    os_log("Error parsing returned json", log: OSLog.default, type: .error, error.localizedDescription)
                }
            } else {
                os_log("Undefined error while fetching fill data from gdax", log: OSLog.default, type: .error)
                errors.append(NSError(code:.ExecutionFailed, userInfo: ["errorMessage" as NSString: "Error while fetching data from gdax" as NSString]))
            }
            self.finish(errors: errors)
        })
        task.resume()
    }
}
