//
//  PortfolioViewController.swift
//  cryptoterminal
//
import os
import Cocoa
import GRDB


class PositionViewController: NSViewController, NSTableViewDelegate, NSDraggingDestination, NSSearchFieldDelegate {
    @IBOutlet var positionController: NSArrayController!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var portfolioTableHeaderView: NSTableHeaderView!
    @IBOutlet weak var positionsTable: NSTableView!
    @IBOutlet var deleteMenu: NSMenu!
    @IBOutlet weak var searchField: NSSearchField!
    
    var controller : FetchedRecordsController<Position>!
    let datasource = Datasource.shared
    
    lazy var sheetViewController: NSViewController = {
        return self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "newPositionView"))
            as! NSViewController
    }()
    
    @IBAction func segCtrlClicked(_ sender: Any) {
        self.presentViewControllerAsSheet(sheetViewController)
    }
    
    @IBAction func deleteMenuItemClicked(_ sender: Any) {
        guard let positions = positionController.arrangedObjects as? [Position] else { return }
        let indexOfClickedRow = positionsTable.clickedRow
        let positionToDelete = positions[indexOfClickedRow]
        Position.deletePosition(withId: positionToDelete.id )
        positionsTable.reloadData()
        
    }
    
    @IBOutlet weak var exportAsCSVMenu: NSMenuItem!
    
    
    @IBAction func exportAsCSV(_ sender: Any) {
        let columns = self.positionsTable.tableColumns
        let columnHeaders = columns.map{ $0.identifier.rawValue }
        
        let fileName = "positions.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = columnHeaders.joined(separator: ",") + "\n"
        
        for position in (positionController.arrangedObjects as? [Position]) ?? [] {
            let newLine = "\(position.coin?.name ?? ""),\(position.purchaseDate),\(position.quantity),\(position.purchaseCurrency.code), \(position.costOfPosition), \(position.exchange.name),\(position.side)\n"
            csvText.append(newLine)
        }
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            if let pathUrl = path?.absoluteURL {
                NSWorkspace.shared.open(pathUrl)
            }
        } catch {
            os_log("Failed to create .csv file - %@", log: OSLog.default, type: .error, error.localizedDescription)
        }
        os_log("Path created:- %@", log: OSLog.default, type: .info, path?.absoluteString ?? "path not found")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        positionsTable.delegate = self
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        self.positionController.avoidsEmptySelection = false
        self.controller = try! FetchedRecordsController(
            Datasource.shared.db!,
            request: Position.all()
        )
        self.controller.trackChanges{ controller in
            self.positionController.content = controller.fetchedRecords
        }
        try! self.controller.performFetch()
        DispatchQueue.main.async {
            self.positionController.content = self.controller.fetchedRecords
        }
        NotificationCenter.default.addObserver(self, selector: #selector(PositionViewController.cryptoPricesUpdated(notification:)), name: Notification.Name(CryptoNotification.cryptoUpdatedNotification), object: nil)
    }
    
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        tableView.reloadData()
    }
   
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnIdentifier = tableColumn?.identifier,
            let cell = tableView.makeView(withIdentifier : columnIdentifier, owner: nil) as? NSTableCellView,
            let position = (positionController.arrangedObjects as! [Any])[row] as? Position
            else { return nil }
        switch(columnIdentifier.rawValue){
        case "Position":
            cell.textField?.formatter = CryptoFormatters.cryptoFormatter
            cell.textField?.objectValue = position.quantity
        case "Exchange":
            cell.textField?.objectValue = position.exchange.name
        case "PurchaseCurrency":
            cell.textField?.objectValue = position.purchaseCurrency.code
        case "Coin":
            cell.textField?.objectValue = position.coin?.name
        case "PurchaseDate":
            cell.textField?.objectValue = CryptoFormatters.dateFormatter.string(from: position.purchaseDate)
        case "Cost":
            cell.textField?.objectValue = position.costOfPosition
        case "Side":
            cell.textField?.objectValue = position.side
        default:
            break
        }
        return cell
    }
    
    func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation()
    }
    
    @objc func cryptoPricesUpdated(notification: Notification){
        DispatchQueue.main.async {
            self.positionsTable.reloadData()
        }
    }
}
