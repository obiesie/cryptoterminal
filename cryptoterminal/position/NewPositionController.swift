//
//  NewPositionController.swift
//  cryptoterminal
//

import Cocoa

class NewPositionController: NSViewController, DragDestinationDelegate,  NSTextFieldDelegate, OperationObserver {
    
    @IBOutlet weak var dragDropLabel: NSTextField!
    @IBOutlet weak var amount: NSTextField!
    @IBOutlet weak var coinPopup: NSPopUpButton!
    @IBOutlet weak var date: NSDatePicker!
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var costField: NSTextField!
    @IBOutlet weak var dragAndDrop: DragDestination!
    @IBOutlet weak var alertTextField: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var purchaseCurrencyPopup: NSPopUpButton!
    @IBOutlet weak var sidePopup: NSPopUpButton!
    @IBOutlet weak var amountRowStackView: NSStackView!
    @IBOutlet weak var costRowStackView: NSStackView!
    @IBOutlet weak var exchangeDataImportProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var downloadProgressStatus: NSTextField!
    @IBOutlet weak var exchangeDataImportButton: NSButton!
    weak var delegate : NewPositionControllerDelegate?

    lazy var sheetViewController: NSViewController = {
        let vc = self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "exchangeSelection"))
            as! ExchangeSelectionController
        vc.obDelegate = self
        return vc
    }()
    
    let positionRepo: PositionRepo = SQLiteRepository()
    var coins: [Currency] = [Currency]()
    var currencies = Currency.allCurrencies()
    var fileDropped: Bool = false
    let cryptoExchangeList = CryptoExchange.allCryptoExchanges()
    
    @IBOutlet weak var exchangeListPopup: NSPopUpButton!
    let allowedNumericCharacterSet = CharacterSet(charactersIn: "0123456789.")
    
    func partialStringValidationFailed(for textField: NSTextField) {
        textField.shake(count: 5, for: 0.5, withTranslation: 5)
        textField.wantsLayer = true
        textField.layer?.borderWidth = 1.0
        textField.layer?.borderColor = NSColor.red.cgColor
        
        self.alertTextField.isHidden = false
    }
    
    func partialStringValidationSucceeded(for textField: NSTextField){
        textField.wantsLayer = false
        textField.layer?.borderWidth = 0.0
    }
    
    @IBAction func importDataFromExchangeClicked(_ sender: Any) {
        self.presentViewControllerAsSheet(sheetViewController)
    }
    
    func draggedItemDroppedInView(data: Any?) {
        self.fileDropped = true
        self.dragDropLabel.objectValue = dragAndDrop.filePath
        self.doneButton.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dragAndDrop.delegate = self
        self.amount.delegate = self
        self.costField.delegate = self
        initForm()
    }
    
    private func initForm(){
        self.alertTextField.isHidden = true
        let currentDate = Date()
        date.dateValue = currentDate
        coins = Currency.currencies(ofType: 2)
        
        let items = coins.map( {$0.name.capitalized} )
        coinPopup.removeAllItems()
        coinPopup.addItems(withTitles: items)
        
        amountRowStackView.wantsLayer = true
        costRowStackView.wantsLayer = true
        
        amount.objectValue = nil
        amount.wantsLayer = false
        amount.layer?.borderWidth = 0.0
        
        costField.objectValue = nil
        costField.wantsLayer = false
        costField.layer?.borderWidth = 0.0
        
        purchaseCurrencyPopup.removeAllItems()
        purchaseCurrencyPopup.addItems(withTitles: currencies.map({$0.code}))
        
        self.exchangeListPopup.removeAllItems()
        self.exchangeListPopup.addItems(withTitles: cryptoExchangeList.map{$0.name})
        self.doneButton.isEnabled = false
        
        self.dragDropLabel.objectValue = "Drag and drop csv position file"
        
        self.downloadProgressStatus.isHidden = true
        self.exchangeDataImportProgressIndicator.isHidden = true
    }
    
    override func viewWillAppear(){
        initForm()
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.dismissViewController(self)
    }
    
    @IBAction func doneClicked(_ sender: Any) {
        if self.fileDropped{
            let positions = Position.positionFromFile(filePath: dragAndDrop.filePath!)
            let validPositions = positions.compactMap{ $0 }
            validPositions.forEach{ pos in
                positionRepo.addPosition(position: pos)
            }
        } else {
            guard let coinAmt = CryptoFormatters.decimalFormatter.number(from: amount.stringValue),
                let cost = CryptoFormatters.decimalFormatter.number(from: costField.stringValue)
                else { return }
            let purchaseCurrencyIndex = purchaseCurrencyPopup.indexOfSelectedItem
            let coin = coins[coinPopup.indexOfSelectedItem]
            let datePurchased = date.dateValue
            let purchaseCurrency = currencies[purchaseCurrencyIndex]
            let side = sidePopup.indexOfSelectedItem == 0 ? "BUY" : "SELL"
            let exchange = cryptoExchangeList[ exchangeListPopup.indexOfSelectedItem ]
            let dateOfPosition = CryptoFormatters.dateFormatter.string(from: datePurchased as Date)
            let position = Position.positionFrom(coin: coin, quantity: Double(truncating: coinAmt), dateEntered: dateOfPosition, costOfPosition : Double(truncating: cost), purchaseCurrency: purchaseCurrency, purchaseSide: side, exchangeId: exchange.id)
            positionRepo.addPosition(position: position)
        }
        delegate?.newPositionCreated()
        self.dismiss(nil)
    }
    
    func inputIsValid(for textField : NSTextField) -> Bool{
        return Double(textField.stringValue) != nil ? true : false
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        if inputIsValid(for: amount) && inputIsValid(for: costField){
            self.doneButton.isEnabled = true
        } else {
            self.doneButton.isEnabled = false
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification){
        let textField = obj.object as! NSTextField
        if inputIsValid(for: textField){
            partialStringValidationSucceeded(for: textField)
        } else{
            partialStringValidationFailed(for: textField)
        }
    }
    
    func operationDidStart(operation: Operation) {
        DispatchQueue.main.async(execute: {() -> Void in
            self.exchangeDataImportProgressIndicator.isHidden = false
            self.downloadProgressStatus.isHidden = false
            self.downloadProgressStatus.stringValue = "Downloading data ..."
            self.exchangeDataImportProgressIndicator.startAnimation(self.exchangeDataImportProgressIndicator)
        })
    }
    
    func operation(operation: Operation, didProduceOperation newOperation: Operation) {}
    
    func operationDidFinish(operation: Operation, errors: [NSError]) {
        if errors.isEmpty {
            DispatchQueue.main.async(execute: {() -> Void in
                self.exchangeDataImportProgressIndicator.stopAnimation(self.exchangeDataImportProgressIndicator)
                self.exchangeDataImportProgressIndicator.isHidden = true
                self.downloadProgressStatus.stringValue = "Download complete."
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                self.dismiss(self)
            })
        } else {
            DispatchQueue.main.async(execute: {() -> Void in
                
                self.exchangeDataImportProgressIndicator.stopAnimation(self.exchangeDataImportProgressIndicator)
                self.exchangeDataImportProgressIndicator.isHidden = true
                var defaultErrorMessage = "Download failed."
                if let error = errors.first, let errorMessage = error.userInfo["errorMessage"] as? String {
                    defaultErrorMessage = errorMessage
                }
                self.downloadProgressStatus.stringValue = defaultErrorMessage
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                self.dismiss(self)
            })
        }
    }
}


public extension NSControl {
    
    func shake(count : Float = 4,for duration : TimeInterval = 0.5, withTranslation translation : Float = -5) {
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        animation.repeatCount = count
        animation.duration = duration / TimeInterval(animation.repeatCount)
        
        animation.autoreverses = true
        animation.byValue = translation
        self.wantsLayer = true
        layer?.add(animation, forKey: "shake")
        
    }
}

protocol NewPositionControllerDelegate: class {
    func newPositionCreated()
}

class ExchangeSelectionController : NSViewController {
    
    @IBOutlet weak var exchangeAPIKeyTextField: NSTextField!
    @IBOutlet weak var exchangeSelectionPopup: NSPopUpButton!
    @IBOutlet weak var cancelExchangeDataImportButton: NSButton!
    @IBOutlet weak var importExchangeDataButton: NSButton!
    @IBOutlet weak var exchangeAPISecretTextField: NSTextField!
    @IBOutlet weak var gdaxPassphraseTextField: NSTextField!
    var obDelegate : OperationObserver?
    var queue = CryptoOperationQueue()
    
    @IBOutlet weak var gdaxPassphraseStackView: NSStackView!
    var cryptoExchanges : [CryptoExchange] = CryptoExchange.allCryptoExchanges()
    
    
    @IBAction func exchangeSelectionChanged(_ sender: NSPopUpButton) {
        let exchange = cryptoExchanges[ exchangeSelectionPopup.indexOfSelectedItem ]
        if exchange.name == "GDAX" {
            gdaxPassphraseStackView.isHidden = false
        } else{
            gdaxPassphraseStackView.isHidden = true
        }
    }
    
    @IBAction func cancelDataImportFromExchangeClicked(_ sender: Any) {
        self.dismissViewController(self)
    }
    
    @IBAction func importDataFromExchangeClicked(_ sender: Any) {
        
        let exchange = cryptoExchanges[ exchangeSelectionPopup.indexOfSelectedItem ]
        var task : Operation?
        switch ( exchange.name ){
        case "COINBASE":
            task = GetCoinbaseData(apiKey: exchangeAPIKeyTextField.stringValue, apiSecret: exchangeAPISecretTextField.stringValue)
        case "GDAX":
            task = GetGdaxData(apiKey : exchangeAPIKeyTextField.stringValue,
                                           apiSecret : exchangeAPISecretTextField.stringValue,
                                           passphrase:gdaxPassphraseTextField.stringValue )
        case "POLONIEX":
            task = GetPoloniexData(apiKey : exchangeAPIKeyTextField.stringValue,
                                   apiSecret : exchangeAPISecretTextField.stringValue)
        case "KRAKEN":
            task = GetKrakenData(apiKey : exchangeAPIKeyTextField.stringValue,
                                             apiSecret : exchangeAPISecretTextField.stringValue)
        default:
            break
        }
        if let task = task {
            (task as! CryptoOperation).addObserver(observer: obDelegate!)
            queue.isSuspended = false
            queue.addOperation(task)
        }
        self.dismissViewController(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exchangeSelectionPopup.removeAllItems()
        exchangeSelectionPopup.addItems(withTitles: cryptoExchanges.map( { $0.name } ))
        gdaxPassphraseStackView.isHidden = true
    }
}












