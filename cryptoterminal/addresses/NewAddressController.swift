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
    weak var delegate : NewAddressDelegate?
    var coins : [CryptoAddressType] = [CryptoAddressType]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        var items = [String]()
        coins = CryptoAddressType.allCryptoAddressType()
        for v in coins{
            items.append(v.name.capitalized)
        }
        coinPopup.removeAllItems()
        coinPopup.addItems(withTitles: items)
    }
    
    @IBAction func doneClicked(_ sender: Any) {
        self.dismiss(sender)
        if let address = addressField.objectValue as? String, let addressAlias = addressNicknameTextField.objectValue as? String  {
           // Wallet.add
            Wallet.addWallet( cryptoAddressIdentifier: address,
                              cryptoAddressType: coins[coinPopup.indexOfSelectedItem].id as Int64,
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

