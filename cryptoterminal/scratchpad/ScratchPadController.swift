//
//  ScratchPadController.swift
//  cryptoterminal
//

import Cocoa

class ScratchPadController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var targetLabel: NSTextField!
    @IBOutlet weak var sourceLabel: NSTextField!
    @IBOutlet weak var sourceCurrencyTextField: NSTextField!
    @IBOutlet weak var targetCurrencyTextField: NSTextField!
    
    @IBOutlet weak var fiatCurrencyLabel: NSTextField!
    @IBOutlet weak var sourceCurrencyPopup: NSPopUpButton!
    @IBOutlet weak var targetCurrencyPopup: NSPopUpButton!
    @IBOutlet weak var fiatCurrencyPopup: NSPopUpButton!
    
    let cryptos = Currency.currencies(ofType: 2)
    let fiatCurrencies = Currency.currencies(ofType: 1)
        
    let allowedNumericCharacterSet = CharacterSet(charactersIn: "0123456789.")
    let initialSourceCurrencyIndex = 0
    let initialTargetCurrencyIndex = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        initPopups()
        initLabels()
    }
    
    @IBAction func sourcePopupSelectionChanged(_ sender: Any) {
        sourceLabel.stringValue = cryptos[sourceCurrencyPopup.indexOfSelectedItem].name.capitalized
        updateTargetCurrencyAndFiatEquivalentValues()
    }
    
    @IBAction func targetPopupSelectionChanged(_ sender: Any) {
        targetLabel.stringValue = cryptos[targetCurrencyPopup.indexOfSelectedItem].name.capitalized
        updateTargetCurrencyAndFiatEquivalentValues()
    }
    
    private func initPopups(){
        let extractCurrencyName = {(curr:Currency) -> String in return curr.name.capitalized}
        
        sourceCurrencyPopup.removeAllItems();
        targetCurrencyPopup.removeAllItems();
        sourceCurrencyPopup.addItems(withTitles: cryptos.map(extractCurrencyName))
        targetCurrencyPopup.addItems(withTitles: cryptos.map(extractCurrencyName))
        sourceCurrencyPopup.selectItem(at: initialSourceCurrencyIndex)
        targetCurrencyPopup.selectItem(at: initialTargetCurrencyIndex)
    }
    
    private func initLabels(){
        sourceCurrencyTextField.delegate = self
        targetCurrencyTextField.delegate = self
        targetCurrencyTextField.formatter = CryptoFormatters.cryptoFormatter
        fiatCurrencyLabel.formatter = CryptoFormatters.currencyFormatter
    }
    
    override func controlTextDidChange(_ notification: Notification) {
        updateTargetCurrencyAndFiatEquivalentValues()
    }
    
    private func updateTargetCurrencyAndFiatEquivalentValues(){
        if !sourceCurrencyTextField.stringValue.isEmpty && sourceCurrencyTextField.stringValue.rangeOfCharacter(from: allowedNumericCharacterSet.inverted) == nil{
            let targetCurrencyAmount = PriceConversionService.convertFrom(sourceCurrencySymbol: sourceLabel.stringValue,
                                                                          targetCurrencySymbol: targetLabel.stringValue,
                                                                          amount: sourceCurrencyTextField.doubleValue)
            if let crypto = targetCurrencyAmount.targetCryptoCurrency,
                let fiatEquivalent = targetCurrencyAmount.fiatEquivalent{
                targetCurrencyTextField.doubleValue = crypto
                fiatCurrencyLabel.doubleValue = fiatEquivalent
            }
            
        } else  {
            targetCurrencyTextField.objectValue = nil
            fiatCurrencyLabel.objectValue = nil
        }
    }
}
