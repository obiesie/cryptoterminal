//
//  AddressListController.swift
//  cryptoterminal
//

import Cocoa

class AddressListController: NSViewController, NewAddressDelegate, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var leftCustomView: NSView!
    @IBOutlet weak var topRightView: NSView!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var cryptoAddressTable: NSTableView!
    @IBOutlet weak var qrCodeImageView: NSImageView!
    @IBOutlet weak var cryptoAddressDetailTable: NSTableView!
    @IBOutlet var backgroundView: NSView!
    @IBOutlet var contextMenu: NSMenu!
    
    var repo = SQLiteRepository()
    var cryptos : [Currency] = [Currency]()
    let cryptoAddressTypes = CryptoAddressType.allCryptoAddressType()
    lazy var newAddressSheetViewController: NewAddressController = {
        let viewController = self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "newAddress"))
            as! NewAddressController
        viewController.delegate = self
        return viewController
    }()
    var selectedCryptoAddress : Wallet? {
        didSet {
            if let address = selectedCryptoAddress{
                qrCodeImageView.image = generateQRCode(from: address.address)
            }
        }
    }
    
    fileprivate enum CellIdentifiers {
        static let CryptoCell = "Crypto"
        static let AddressCell = "Address"
        static let BalanceCell = "AddressBalance"
        static let AddressTypeCell = "AddressType"
        static let AliasCell = "Alias"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cryptos = Currency.allCurrencies().filter{$0._currencyTypeId == 2}
        initCustomViews()
        initSelections()
        cryptoAddressTable.delegate = self
        cryptoAddressTable.dataSource = self
        cryptoAddressDetailTable.delegate = self
        cryptoAddressDetailTable.dataSource = self
        repo.delegate = Portfolio.shared
        repo.walletDelegate = Portfolio.shared
        NotificationCenter.default.addObserver(self, selector: #selector(AddressListController.methodOfReceivedNotification1(notification:)), name: Notification.Name(CryptoNotification.cryptoAddressUpdatedNotification), object: nil)
    }
    
    func newAddressAdded() {
        cryptoAddressTable.reloadData()
    }
    
    private func generateQRCode(from string: String) -> NSImage?{
        let data = string.data(using: String.Encoding.isoLatin1)
        if let filter = CIFilter(name : "CIQRCodeGenerator"){
            filter.setValue(data, forKey : "inputMessage")
            
            guard let qrCodeImage = filter.outputImage else {return nil}
            let scaleX = qrCodeImageView.frame.size.width / qrCodeImage.extent.size.width
            let scaleY = qrCodeImageView.frame.size.height / qrCodeImage.extent.size.width
            
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            
            if let output = filter.outputImage?.transformed(by: transform){
                let rep = NSCIImageRep(ciImage: output)
                let image =  NSImage(size: rep.size)
                image.addRepresentation(rep)
                return image
            }
        }
        return nil
    }
    
    
    @IBAction func addNewAddressClicked(_ sender: Any){
        self.presentViewControllerAsSheet(newAddressSheetViewController)
    }
    
    func deleteSelectedAddress(){
        let selectedWallet = Wallet.allWallets()[ cryptoAddressTable.selectedRow ]
        if let walletId = selectedWallet.id {
            repo.deleteWallet(withId: walletId)
            self.cryptoAddressTable.reloadData()
        }
    }

   
    private func initSelections(){
        let cryptoAddresses =  Wallet.allWallets()
        if let defaultAddressSelection = cryptoAddresses.first{
            self.selectedCryptoAddress = defaultAddressSelection
        }
    }
    
    private func initCustomViews(){
        topRightView.wantsLayer = true
        topRightView.layer?.backgroundColor = NSColor.white.cgColor
        leftCustomView.wantsLayer = true
        leftCustomView.layer?.backgroundColor = NSColor.white.cgColor
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    @objc func methodOfReceivedNotification1(notification: Notification){
        DispatchQueue.main.async {
            self.cryptoAddressTable.reloadData()
            self.cryptoAddressDetailTable.reloadData()
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification){
        if self.cryptoAddressTable.selectedRow > -1 {
            let selectedRow =  Wallet.allWallets()[self.cryptoAddressTable.selectedRow]
            self.selectedCryptoAddress = selectedRow
            self.cryptoAddressDetailTable.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int{
        var rowCount = 0
        if tableView == self.cryptoAddressTable{
            rowCount = Wallet.allWallets().count
        } else{
            if let cryptoAddress = selectedCryptoAddress{
                rowCount = cryptoAddress.allCryptoBalances().count
            }
        }
        return rowCount
    }
    
    
    private func tableViewForAddressList(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let item =  Wallet.allWallets()[row]
        var cellValue = ""
        var cellIdentifier = ""
        switch(tableColumn?.identifier.rawValue){
        case "AddressType"?:
            if let cryptoAddressType = cryptoAddressTypes.first(where: { $0.id == item.addressTypeId }) {
                cellValue = cryptoAddressType.name
            }
            cellIdentifier = CellIdentifiers.AddressTypeCell
        case "Address"?:
            cellValue = item.address
            cellIdentifier = CellIdentifiers.AddressCell
        case "Alias"?:
            if let nickName = item.walletAlias {
                cellValue = nickName
            }
            cellIdentifier = CellIdentifiers.AliasCell
        default:
            NSLog("Unrecognized column identifier")
            
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = cellValue
            return cell
        }
        return nil
    }
    
    private func tableViewForAddressDetail(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        if let cryptoAddress = selectedCryptoAddress{
            let cryptoAddress = cryptoAddress.allCryptoBalances()[row]
            var cellValue = ""
            var cellIdentifier = ""
            
            switch(tableColumn?.identifier.rawValue){
            case "Crypto"?:
                if let index = cryptos.index(where: { $0.id == cryptoAddress.currencyId }) {
                    cellValue = (cryptos[index].name)
                    cellIdentifier = CellIdentifiers.CryptoCell
                }
            case "AddressBalance"?:
                cellValue = String(cryptoAddress.quantity)
                cellIdentifier = CellIdentifiers.BalanceCell
            default:
                NSLog("Unrecognized column")
            }
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = cellValue
                return cell
            }
        }
        return nil
    }
    
    @IBAction func deleteClicked(_ sender: Any) {
        let selectedWallet = Wallet.allWallets()[ cryptoAddressTable.selectedRow ]
        if let walletId = selectedWallet.id {
            repo.deleteWallet(withId: walletId)
            self.cryptoAddressTable.reloadData()
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var view : NSView? 
        switch(tableView){
        case self.cryptoAddressTable:
            view = tableViewForAddressList(tableView, viewFor: tableColumn, row: row)
            break
        case self.cryptoAddressDetailTable:
            view = tableViewForAddressDetail(tableView, viewFor: tableColumn, row: row)
            break
        default:
            break
        }
        return view
    }
}

class VerticallyAlignedTextFieldCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        let newRect = NSRect(x: 0, y: (rect.size.height - 22) / 2, width: rect.size.width, height: 22)
        return super.drawingRect(forBounds: newRect)
    }
}

