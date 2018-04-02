//
//  GeneralPrefsPaneViewController.swift
//  cryptoterminal
//


import Cocoa

class GeneralPrefsPaneViewController: NSViewController {

    @IBOutlet weak var currencyPopup: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialiseCurrencies()
    }
    
    func initialiseCurrencies(){
        
        let filePath = Bundle.main.path(forResource: "currencies", ofType: "plist")
        var currencyList = [String]()
        
        if let currencyFeed = NSArray(contentsOfFile: filePath!) as? [String] {
            
            for currency in currencyFeed {
                currencyList.append(currency)
            }
        }
        self.currencyPopup.removeAllItems()
        self.currencyPopup.addItems(withTitles: currencyList)
    }
}
