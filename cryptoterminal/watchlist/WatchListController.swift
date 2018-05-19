 //
 //  WatchListController.swift
 //  cryptoterminal
 //
 
 
 import Cocoa
 import GRDB
 import CorePlot
 import SwiftDate
 
 
 class WatchListController: NSViewController, CPTPlotDelegate  {
    @IBOutlet weak var hostView: MouseMovedAwareCPTGraphHostingView? = nil
    @IBOutlet weak var watchListTable: NSTableView!
    @IBOutlet var watchListArrayController: NSArrayController!
    @IBOutlet var rightClickMenu: NSMenu!
    @IBOutlet weak var periodPopup: NSPopUpButton!
    
    private var scatterPlot : GraphConfig?
    private var watchList : WatchList?
    private var selectedWatchListItem : CurrencyPair? = nil
    
    weak var delegate:GraphConfigDelegate?
    private var selectedPeriod = "7D"
    
    static let formats : [Formatter:Set<String>] = [
        CryptoFormatters.decimalFormatter:["standardDeviation", "movingAverage"],
        CryptoFormatters.percentFormatter:["priceChange"],
        CryptoFormatters.currencyFormatter:["price"]
    ]
    
    lazy var sheetViewController: NSViewController = {
        return self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "newWatchList"))
            as! NSViewController
    }()
    
    @IBAction func addToWatchListClicked(_ sender: Any) {
        self.presentViewControllerAsSheet(sheetViewController)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        watchListTable.delegate = self
        self.scatterPlot = ScatterGraphConfig()
        self.scatterPlot?.delegate = self
        hostView?.delegate = self.scatterPlot as? MouseMovedAwareCPTGraphHostingViewDelegate
        
        let sqliteRepo = SQLiteRepository()
        self.watchList = SimpleWatchList(currencyPairRepo: sqliteRepo, exchangeRateRepo: sqliteRepo)
        self.periodPopup.removeAllItems()
        self.periodPopup.addItems(withTitles: ["7D", "1D", "12H", "6H", "1H", "30M"])
        if let _watchList = self.watchList {
            self.watchListArrayController.content = _watchList.watchListedItems()
            if let _selectedWatchListItem = _watchList.watchListedItems().first {
                self.selectedWatchListItem = _selectedWatchListItem
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(WatchListController.cryptoUpdatedNotificationHandler(notification:)),
                                               name: Notification.Name(CryptoNotification.cryptoUpdatedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WatchListController.historicalPriceUpdatedNotificationHandler(notification:)),
                                               name: Notification.Name(CryptoNotification.hisoricalPriceUpdateNotification), object: nil)
    }
    
    override func viewDidAppear(){
        super.viewDidAppear()
        if let selectedCurrPair = self.selectedWatchListItem, let _watchList = watchList {
            let dataPoints = _watchList.exchangeRates(for: selectedCurrPair,
                                                      since: Date().addingTimeInterval(TimeInterval(7.0*24.0*60.0*60.0)).timeIntervalSince1970)
            self.scatterPlot?.setUpPlot(for:selectedPeriod, using:dataPoints, usingFormatter: selectedCurrPair.denominatedCurrency.formatter )
        }
    }
    
    @objc func cryptoUpdatedNotificationHandler(notification: Notification){
        DispatchQueue.main.async {
            if let _watchList = self.watchList{
                self.watchListArrayController.content = _watchList.watchListedItems()
            }
        }
    }
    
    @objc func historicalPriceUpdatedNotificationHandler(notification: Notification){
        DispatchQueue.main.async{
            if let selectedPair = self.watchListArrayController.selectedObjects.first as? CurrencyPair,
                let _watchList = self.watchList {
                let since = Date().addingTimeInterval(TimeInterval(7.0*24.0*60.0*60.0))
                self.scatterPlot?.refreshPlot(for: self.selectedPeriod, using: _watchList.exchangeRates(for: selectedPair, since:since.timeIntervalSince1970 ), usingFormatter: selectedPair.denominatedCurrency.formatter )
            }
        }
    }
    
    @IBAction func removeWatchListedItem(_ sender: Any){
        if let selectedRows = self.watchListArrayController.selectedObjects as? [CurrencyPair]{
            for currencyPair in selectedRows {
                currencyPair.watchListed = false
                CurrencyPair.update(pair: currencyPair)
            }
        }
    }
    
    @IBAction func periodSelected(_ sender: Any) {
        if let watchListedPair = periodPopup.selectedItem, let _selectedWatchListItem = selectedWatchListItem {
            self.selectedPeriod = watchListedPair.title
            let since = Date().addingTimeInterval(TimeInterval(7.0*24.0*60.0*60.0))
            if let dataPoints = self.watchList?.exchangeRates(for: _selectedWatchListItem, since: since.timeIntervalSince1970) {
                self.scatterPlot?.refreshPlot(for: self.selectedPeriod, using: dataPoints,
                                              usingFormatter: _selectedWatchListItem.denominatedCurrency.formatter )
                self.watchListTable.reloadData()
            }
        }
        self.watchListArrayController.rearrangeObjects()
    }
 }
 
 extension WatchListController: NSTableViewDelegate{
    
    func tableViewSelectionDidChange(_ notification: Notification){
        self.selectedWatchListItem = self.watchListArrayController.selectedObjects.first as? CurrencyPair
        let cutOff = Date().addingTimeInterval(TimeInterval(7.0*24.0*60.0*60.0)).timeIntervalSince1970
        if let _selectedWatchListItem = selectedWatchListItem, let dataPoints = self.watchList?.exchangeRates(for: _selectedWatchListItem, since:cutOff)  {
            self.scatterPlot?.setUpPlot(for:selectedPeriod, using:dataPoints,
                                        usingFormatter: _selectedWatchListItem.denominatedCurrency.formatter )
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        if let cell = tableView.makeView(withIdentifier:
            NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier.rawValue)!), owner: nil) as? NSTableCellView,
            let rowObjs = self.watchListArrayController.arrangedObjects as? [CurrencyPair] {
            for (formatter, columns) in WatchListController.formats {
                if columns.contains((tableColumn?.identifier.rawValue)!){
                    cell.textField?.formatter = formatter
                }
            }
            if tableColumn?.identifier.rawValue == "price"{
                let rowCurrency = rowObjs[row].denominatedCurrency
                cell.textField?.formatter = rowCurrency.formatter
            }
            if tableColumn?.identifier.rawValue == "priceChange"{
                let currencyPair = rowObjs[row]
                let secoundCount = periodToMinutes(period: self.selectedPeriod)*60
                let dateCutOff = NSDate().addingTimeInterval(TimeInterval(-secoundCount))
                
                let rateDelta = currencyPair.exchangeRateDelta(since: dateCutOff.timeIntervalSince1970)
                cell.textField?.objectValue = rateDelta
                
                if rateDelta > 0 {
                    cell.imageView?.image = NSImage(named: NSImage.Name.statusAvailable)
                    cell.textField?.textColor = NSColor(calibratedRed: 0.06, green: 0.80, blue: 0.48, alpha: 1.00)
                } else {
                    cell.imageView?.image = NSImage(named: NSImage.Name.statusUnavailable)
                    cell.textField?.textColor = NSColor(calibratedRed: 0.92, green: 0.28, blue: 0.25, alpha: 1.0)
                }
            }
            return cell
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat{
        return 25
    }
 }
 
 extension WatchListController: GraphConfigDelegate {
    func didFinishSetUp(sender: Any) {
        if let plot = (sender as? ScatterGraphConfig)?.plot {
            self.hostView?.hostedGraph = plot
        }
    }
    func didFinishRefresh(sender: Any) {}
 }
 
 func periodToMinutes(period:String) -> Int {
    let periodMultiplicativeFactor = [ "M" : 1, "H" : 60, "D" : 1440 ]
    var mins = 0
    if let periodType = period.last,
        let multiplicativeFactor = periodMultiplicativeFactor[String(periodType)],
        let periodNumericForm = Int(period.dropLast()) {
        mins = periodNumericForm * multiplicativeFactor
    }
    return mins
 }
 
 
