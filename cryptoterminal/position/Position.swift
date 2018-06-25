//
//  Position.swift
//  cryptoterminal
//
import CSVImporter
import Foundation
import GRDB

class Position : NSObject, RowConvertible, TableMapping, Persistable {
    
    var id : String
    @objc let baseCurrencyId : Int64
    let _quantity : Double
    @objc var defaultMarketValue : Double {
        var _marketValue = 0.0
        if let currencyCode = Locale.current.currencyCode{
            _marketValue = marketValue(in: currencyCode)
        }else{
            _marketValue = marketValue(in:"USD")
        }
        return _marketValue
    }
    @objc var quantity : Double {
        return _quantity
    }
    let costOfPosition : Double
    @objc let purchaseDate : Date
    private let purchaseCurrencyId : Int
    let side : String
    let exchangeId : Int
    @objc var exchange : CryptoExchange {
        var exch : CryptoExchange?
        do {
            exch = try Datasource.shared.db!.read{ d in try CryptoExchange.filter(Column("id") == exchangeId).fetchOne(d) }
        }catch let error {
            print(error.localizedDescription)
        }
        return exch!
    }
    @objc var baseCurrency : Currency {
        var currency : Currency?
        do {
            currency = try Datasource.shared.db!.read{ d in try Currency.filter(Currency.Columns.ID == baseCurrencyId).fetchOne(d) }
        }catch let error {
            print(error.localizedDescription)
        }
        return currency!
    }
    
    var purchaseCurrency : Currency  {
        var currency : Currency?
        do {
            currency = try Datasource.shared.db!.read{ d in try Currency.filter(Currency.Columns.ID == purchaseCurrencyId).fetchOne(d) }
        }catch let error {
            print(error.localizedDescription)
        }
        return currency!
    }
    
    static let ALLOWED_TRANSACTION_TYPES : Set = ["sell", "buy"]
    
    var coin : Currency? {
        var crypto : Currency?
        do {
            crypto = try Datasource.shared.db!.read{ d in try Currency.filter(Currency.Columns.ID == self.baseCurrencyId).fetchOne(d) }
        } catch let error {
            print(error.localizedDescription)
        }
        return crypto
    }
    
    @objc var name : String {
        return (self.coin?.name) ?? ""
    }
    
    
    init(itemId: Int64, quantity: Double, purchaseDate: Date, costOfPosition : Double, purchaseCurrency : Int,
         side : String, exchangeId : Int, positionId : String?=nil) {
        self._quantity = quantity
        self.purchaseDate = purchaseDate
        self.costOfPosition = costOfPosition
        self.baseCurrencyId = itemId
        self.purchaseCurrencyId = purchaseCurrency
        self.side = side.uppercased(with: Locale.current)
        self.id = positionId ?? UUID().uuidString
        self.exchangeId = exchangeId
        super.init()
    }
    
    required init(row: Row) {
        id = row["ID"]
        _quantity = row["AMOUNT"]
        costOfPosition = row[ "COST"]
        purchaseDate = CryptoFormatters.coinbaseDateFormatter.date(from: row["PURCHASE_DATE"])!
        baseCurrencyId = row["CURRENCY"]
        purchaseCurrencyId = row["PURCHASE_CURRENCY"]
        side = row["SIDE"]
        exchangeId = row[ "EXCHANGE"]
        super.init()
    }
    
    class var databaseTableName : String {
        return "Position"
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["ID"] = id
        container["CURRENCY"] = baseCurrencyId
        container["AMOUNT"] = _quantity
        container["COST"] = costOfPosition
        container["PURCHASE_DATE"] = CryptoFormatters.coinbaseDateFormatter.string(from: purchaseDate)
        container["PURCHASE_CURRENCY"] = purchaseCurrencyId
        container["SIDE"] = side
        container["EXCHANGE"] = exchangeId
    }
    
    func didInsert(with rowID: String, for column: String?) {
        id = rowID
    }
    
    func marketValue(in currency : String) -> Double {
        var currencyPair : CurrencyPair?
        var marketValue = 0.0
        do {
            let denomCurrency = try Datasource.shared.db!.read{
                db in try Currency.filter(Currency.Columns.CODE == currency.uppercased(with: Locale.current)).fetchOne(db)
            }
            currencyPair = try Datasource.shared.db!.read{
                db in try CurrencyPair.filter(CurrencyPair.Columns.BASE_CURRENCY == baseCurrencyId &&
                    CurrencyPair.Columns.DENOMINATED_CURRENCY == denomCurrency?.id).fetchOne(db)
            }
        } catch let error {
            print(error.localizedDescription)
        }
        if let currPair = currencyPair{
            marketValue = currPair.spotRate * quantity
        }
        return marketValue
    }
    
    func update(){
        try! Datasource.shared.db?.inDatabase{
            db in try self.update(db)
        }
    }
    
    static func allPositions() -> [Position]{
        return try! Datasource.shared.db!.inDatabase{
            db in try Position.fetchAll(db)
        }
    }
    
    static func deletePosition(withId positionId: String){
        _ = try! Datasource.shared.db!.inDatabase{ db in try Position.deleteOne(db, key: positionId) }
    }
    
    static func positionFrom(coin : Currency, quantity : Double, dateEntered : String,
                             costOfPosition : Double, purchaseCurrency:Currency, purchaseSide:String,
                             exchangeId:Int) -> Position{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: dateEntered) ?? Date()
        let pos = Position(itemId: Int64(coin.id), quantity: quantity, purchaseDate: date,
                           costOfPosition: costOfPosition, purchaseCurrency: purchaseCurrency.id,
                           side:purchaseSide, exchangeId:exchangeId)
        return pos
    }
    
    static func addPosition(position : Position){
        try! Datasource.shared.db?.inDatabase{ db in try position.save(db)}
    }
    
    static func positionFromFile(filePath:String) -> [Position?]{
        let importer = CSVImporter<[String:String]>(path: filePath)
        let importedRecords = (importer.importRecords(structure: {_ in }) { $0 }).map{ Dictionary(uniqueKeysWithValues:
            $0.map { element in (element.key.localizedUppercase, element.value)  } ) }
        var importStatus = [Position?]()
        
        for (_, importedRecord) in importedRecords.enumerated(){
            guard let _pair = importedRecord[CSVHeaders.PAIR],
                let _purchaseDate = importedRecord[CSVHeaders.PURCHASE_DATE],
                let _quantity = importedRecord[CSVHeaders.AMOUNT],
                let _cost = importedRecord[CSVHeaders.COST],
                let _side = importedRecord[CSVHeaders.SIDE],
                let _exchangeName = importedRecord[CSVHeaders.EXCHANGE_NAME],
                let currencyPair = Util.currencyPairs(from: _pair),
                let baseCurrency = (Currency.currency(by: currencyPair.baseCurrency)),
                let purchaseCurrency = (Currency.currency(by: currencyPair.counterCurrency)),
                let exchange = CryptoExchange.allCryptoExchanges()
                    .filter({$0.name.localizedUppercase==_exchangeName.localizedUppercase}).first
                else {
                    importStatus.append( nil )
                    continue
            }
            if let cost = Double(_cost), let quantity = Double(_quantity)  {
                let position = Position.positionFrom(coin: baseCurrency, quantity: quantity,
                                                     dateEntered: _purchaseDate,
                                                     costOfPosition: cost, purchaseCurrency : purchaseCurrency,
                                                     purchaseSide:_side, exchangeId:exchange.id)
                importStatus.append(position)
            } else{
                importStatus.append(nil)
            }
        }
        return importStatus
    }
    
    private static func reduceSplitOrders( fieldsToCombine : [String]) -> (( inout [String:String], [String:Any])->()) {
        let reduceClosure = { ( finalMap: inout [String:String], reducingMap: [String:Any])  in
            reducingMap.forEach { (k,v) in
                if (fieldsToCombine.contains(k) ) {
                    if let stringVal = v as? String, let numericVal = Double(stringVal),
                        let finalMapVal = Double(finalMap[k] ?? "0") {
                        finalMap[k] =  String(finalMapVal + numericVal)
                    }
                } else{
                    if let stringVal = v as? String{
                        finalMap[k] = stringVal
                    } else if let numericVal = v as? Double{
                        finalMap[k] = String(numericVal)
                    }
                }
            }
        }
        return reduceClosure
    }
    
    static func parseGdaxData( transactions : [[String : Any]]) -> [Position] {
        let exchange = CryptoExchange.allCryptoExchanges()
            .filter({$0.name.localizedUppercase==GetGdaxData.exchangeName.localizedUppercase}).first
        for d in transactions{
            let n = d["order_id"]
            if n == nil {
                print(d)
            }
            
        }
        let groups = Dictionary(grouping: transactions, by: { $0["order_id"] as! String })
        let parsedTransactions = groups.values.map{ $0.reduce(into : [String:String](),
                                                              reduceSplitOrders(fieldsToCombine:["size", "fee"]))}
        var parsedPositions = [Position?]()
        for transaction in parsedTransactions {
            if let vol = Double(transaction["size"] ?? ""),
                let exchangeRate = Double(transaction["price"] ?? ""),
                let _ = Double(transaction["fee"] ?? ""),
                let currencyPairString = transaction["product_id"],
                let currencyPair = Util.currencyPairs(from: currencyPairString),
                let baseCurrencyId = (Currency.currency(by: currencyPair.baseCurrency)?.id),
                let purchaseCurrency = (Currency.currency(by: currencyPair.counterCurrency)?.id),
                let purchaseDateString = transaction["created_at"],
                let purchaseDate = CryptoFormatters.gdaxDateFormatter.date(from: purchaseDateString),
                let side = transaction["side"], ALLOWED_TRANSACTION_TYPES.contains(side),
                let positionId = transaction["order_id"],
                let _exchange = exchange {
                
                let position = Position(itemId: Int64(baseCurrencyId), quantity: vol, purchaseDate: purchaseDate,
                                        costOfPosition : exchangeRate*vol, purchaseCurrency : purchaseCurrency,
                                        side : side, exchangeId : _exchange.id,
                                        positionId:positionId)
                parsedPositions.append( position )
            }
        }
        return parsedPositions.compactMap{$0}
    }
    
    
    static func parseCoinbaseData( transactions : [[String:Any]] ) -> [Position] {
        let exchange = CryptoExchange.allCryptoExchanges()
            .filter({$0.name.localizedUppercase==GetCoinbaseData.exchangeName.localizedUppercase}).first
        var parsedPositions = [Position?]()
        for transaction in transactions{
            if let amountData = transaction["amount"] as? [ String :  String ],
                let amtString = amountData["amount"],
                let amount = Double(amtString),
                let currencyCode = amountData["currency"],
                let currency = Currency.currency(by: currencyCode), currency._currencyTypeId == 2,
                let nativeAmountData = transaction["native_amount"] as? [ String :  String ],
                let nativeAmountString = nativeAmountData["amount"],
                let nativeAmount = Double(nativeAmountString)?.magnitude,
                let nativeAmountCurrency = nativeAmountData["currency"],
                let nativeAmountCurrencyId = (Currency.currency(by: nativeAmountCurrency)?.id),
                let purchaseDateString = transaction["updated_at"] as? String,
                let purchaseDate = CryptoFormatters.coinbaseDateFormatter.date(from: purchaseDateString),
                let side = transaction["type"] as? String, ALLOWED_TRANSACTION_TYPES.contains(side),
                let positionId = transaction["id"] as? String,
                let _exchange = exchange {
                
                
                parsedPositions.append( Position(itemId: Int64(currency.id), quantity: amount, purchaseDate: purchaseDate,
                                                 costOfPosition : nativeAmount, purchaseCurrency : nativeAmountCurrencyId,
                                                 side : side, exchangeId : _exchange.id,
                                                 positionId:positionId) )
            }
        }
        return parsedPositions.compactMap{ $0 }
    }
    
    static func parsePoloniexData(transactionData: [[String:Any]]) -> [Position]{
        let exchange = CryptoExchange.allCryptoExchanges()
            .filter({$0.name.localizedUppercase==GetPoloniexData.exchangeName.localizedUppercase}).first
        var parsedPositions = [Position]()
        let groups = Dictionary(grouping: transactionData, by: { $0["orderNumber"]! as! String })
        let transactions = groups.values.map( {$0.reduce(into : [:], reduceSplitOrders(fieldsToCombine: ["amount", "total", "fee"]))})
        for transaction in transactions {
            if let currencyPairString = transaction["pair"],
                let currencyPair = Util.currencyPairs(from: currencyPairString),
                let vol = Double(transaction["amount"] ?? ""),
                let _ = Double( transaction["rate"] ?? ""),
                let _ = Double( transaction["fee"] ?? ""),
                let cost = Double( transaction["total"] ?? ""),
                let baseCurrencyId = (Currency.currency(by: currencyPair.counterCurrency)?.id),
                let counterCurrency = (Currency.currency(by: currencyPair.baseCurrency)?.id),
                let purchaseDateString = transaction["date"],
                let purchaseDate = CryptoFormatters.poloniexDateFormatter.date(from: purchaseDateString),
                let side = transaction["type"], ALLOWED_TRANSACTION_TYPES.contains(side),
                let positionId = transaction["orderNumber"] ,
                let _exchange = exchange {
                
                parsedPositions.append( Position(itemId: Int64(baseCurrencyId), quantity: vol,
                                                 purchaseDate: purchaseDate, costOfPosition : cost,
                                                 purchaseCurrency : counterCurrency, side : side,
                                                 exchangeId : _exchange.id,
                                                 positionId:positionId) )
            }
        }
        return parsedPositions
    }
    
    static func parseKrakenData(transactionsData : [ [String:Any] ]) -> [Position]{
        let exchange = CryptoExchange.allCryptoExchanges()
            .filter({$0.name.localizedUppercase==GetKrakenData.exchangeName.localizedUppercase}).first
        
        var parsedPositions = [Position?]()
        let groups = Dictionary(grouping: transactionsData, by: { $0["ordertxid"]! as! String })
        let transactions = groups.values.map( {$0.reduce(into : [:], reduceSplitOrders(fieldsToCombine: ["vol", "cost", "fee", "price"]))})
        for transaction in transactions{
            if let currencyPairString = transaction["pair"],
                let currencyPair = Util.currencyPairs(from: currencyPairString),
                let cost = Double(transaction["cost"] ?? ""),
                let vol = Double(transaction["vol"] ?? ""),
                let baseCurrencyId = (Currency.currency(by: currencyPair.baseCurrency)?.id),
                let purchaseCurrency = (Currency.currency(by: currencyPair.counterCurrency)?.id),
                let purchaseDateString = transaction["time"],
                let purchaseDateTimeInterval = Double(purchaseDateString),
                let side = transaction["type"], ALLOWED_TRANSACTION_TYPES.contains(side),
                let positionId = transaction["ordertxid"],
                let _exchange = exchange {
                
                parsedPositions.append( Position(itemId: Int64(baseCurrencyId), quantity: vol,
                                                 purchaseDate: Date(timeIntervalSince1970:purchaseDateTimeInterval),
                                                 costOfPosition : cost, purchaseCurrency : purchaseCurrency,
                                                 side : side, exchangeId : _exchange.id,
                                                 positionId:positionId) )
            }
        }
        return parsedPositions.compactMap{ $0 }
    }
    
    static func positionFrom(exchange:Exchange, transactionData: [[String:Any]]) -> [Position]{
        var positions = [Position]()
        if let function = Exchange.parseDataAlgorithm(exchange: exchange) {
            positions = function(transactionData)
        }
        return positions
    }
}

enum Exchange {
    case KRAKEN, COINBASE, GDAX, POLONIEX
    
    static func parseDataAlgorithm(exchange: Exchange) -> (([[String:Any]]) -> [Position])? {
        var algo :  ([[String: Any]]) -> [Position]
        switch(exchange){
        case .KRAKEN:
            algo = Position.parseKrakenData
        case .COINBASE:
            algo = Position.parseCoinbaseData
        case .GDAX:
            algo = Position.parseGdaxData
        case .POLONIEX:
            algo = Position.parsePoloniexData
        }
        return algo
    }
}
