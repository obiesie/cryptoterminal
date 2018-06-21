//
//  NewAddressController.swift
//  cryptoterminal
//


import Cocoa

class NewAddressController: NSViewController, WalletPersistenceDelegate, OperationObserver {
    
    @IBOutlet weak var addressNicknameTextField: NSTextField!
    @IBOutlet weak var coinPopup: NSPopUpButton!
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var isERC20TokenCheck: NSButtonCell!
    weak var delegate : NewAddressDelegate?
    var queue = CryptoOperationQueue()
    var coins : [CryptoAddressType] = [CryptoAddressType]()
    var repo = SQLiteRepository()

    override func viewDidLoad() {
        super.viewDidLoad()
        var addressTypes = [String]()
        repo.walletDelegate = self
        coins = CryptoAddressType.allCryptoAddressType()
        for v in coins {
            addressTypes.append(v.name.capitalized)
        }
        coinPopup.removeAllItems()
        coinPopup.addItems(withTitles: addressTypes)
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
        }
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        self.dismiss(sender)
    }
    
    func addedWallet(sender: WalletRepo, wallet: Wallet) {
        let task = GetAddressBalance(walletAddresses: [wallet])
        (task as CryptoOperation).addObserver(observer: self)
        queue.isSuspended = false
        queue.addOperation(task)
    }

    func deletedWallet(sender: WalletRepo, walletId: Int) {}
    
    func operationDidStart(operation: Operation) {}
    
    func operation(operation: Operation, didProduceOperation newOperation: Operation) {}
    
    func operationDidFinish(operation: Operation, errors: [NSError]) {
        delegate?.newAddressAdded()
    }
}


protocol NewAddressDelegate: class {
    func newAddressAdded()
}

