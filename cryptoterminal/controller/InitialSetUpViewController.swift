
//
//  InitialSetUpViewController.swift
//  cryptoterminal
//


import Cocoa

class InitialSetUpViewController: NSViewController {

    @IBOutlet weak var currencyPopup: NSPopUpButton!
    @IBOutlet weak var finishSetupButton: NSButton!
    weak var delegate:CurrencySelectionDelegate?
    
    lazy var sheetViewController: NSViewController = {
        return self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "newPositionView"))
            as! NSViewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialiseCurrencies()
    }
    
    @IBAction func finishSetupClicked(_ sender: Any) {
        self.dismiss(sender)
        UserDefaults.standard.set(true, forKey: "CurrencySet")
        delegate?.currencySelectionDidFinish()
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

protocol CurrencySelectionDelegate: class {
    func currencySelectionDidFinish()
}
