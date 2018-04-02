//
//  NewWatchListController.swift
//  cryptoterminal
//

import Cocoa

class NewWatchListController: NSViewController {
    
    let sqliteRepo = SQLiteRepository()
    var currencyPairs = [CurrencyPair]()
    @IBOutlet weak var addToWatchList: NSButton!
    @IBOutlet weak var currencyPairPopup: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencyPairs.append(contentsOf:sqliteRepo.allCurrencyPairs())
        let currencyPairTitles = currencyPairs.map{return $0.code}.sorted()
        currencyPairPopup.removeAllItems()
        currencyPairPopup.addItems(withTitles: currencyPairTitles)
    }
    
    @IBAction func addToWatchListClicked(_ sender: Any) {
        if let watchListedPair = currencyPairs.first(where: {$0.code == self.currencyPairPopup.selectedItem?.title}) {
            watchListedPair.watchListed = true
            sqliteRepo.updateCurrencyPair(pair: watchListedPair)
        }
        self.dismiss(self)
    }
}
