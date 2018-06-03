//
//  NewAddressController.swift
//  cryptoterminal
//


import Cocoa

class NewAddressController: NSViewController {

    @IBOutlet weak var addressNicknameTextField: NSTextField!
    @IBOutlet weak var coinPopup: NSPopUpButton!
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var isERC20TokenCheck: NSButtonCell!
    weak var delegate : NewAddressDelegate?
    var coins : [CryptoAddressType] = [CryptoAddressType]()
    var repo = SQLiteRepository()

    override func viewDidLoad() {
        super.viewDidLoad()
        var items = [String]()
        //repo.walletDelegate = delegate
        coins = CryptoAddressType.allCryptoAddressType()
        for v in coins {
            items.append(v.name.capitalized)
        }
        coinPopup.removeAllItems()
        coinPopup.addItems(withTitles: items)
    }
    
    @IBAction func doneClicked(_ sender: Any) {
        self.dismiss(sender)
        let addressTypeId = coins[coinPopup.indexOfSelectedItem].id
        
        let addressTypes = CryptoAddressType.allCryptoAddressType()
        let addressType = addressTypes.filter{$0.id == addressTypeId }.first
        if let address = addressField.objectValue as? String, let addressAlias = addressNicknameTextField.objectValue as? String,
            let _addressType = addressType {
            repo.addWallet(cryptoAddressIdentifier: address,
                           cryptoAddressType: _addressType.id,
                           addressNickname: addressAlias)
            delegate?.newAddressAdded()
        }
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        self.dismiss(sender)
    }
}


protocol NewAddressDelegate: class {
    func newAddressAdded()
}

