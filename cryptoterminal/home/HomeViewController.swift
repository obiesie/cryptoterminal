//
//  HomeViewController.swift
//  cryptoterminal
//

import Cocoa
import CorePlot


class HomeViewController: NSViewController, NSSplitViewDelegate {
    
    @IBOutlet var splitview  : NSSplitView?
    @IBOutlet weak var homesplitView: NSSplitView!
    @IBOutlet weak var homeTopSplitView: NSSplitView!
    @IBOutlet weak var marketValueLabel: NSTextField!
    @IBOutlet weak var summaryTable: NSTableView!
    
    @IBOutlet var hostView : CPTGraphHostingView?
    @IBOutlet var positionSummaryController: NSArrayController!
    
    var barPlot : Graph?
    private var crytpos = [Currency]()
    
    let portfolio = Portfolio.shared //Portfolio(balanceRepo: SQLiteRepository())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSplitView()
        configureValueDisplay()
        configurePortfolioSummaryTable()
        self.barPlot = PortfolioChart.portfolioChart(from: portfolio)
        self.barPlot?.delegate = self
        self.portfolio.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.priceUpdatedObserver(notification:)), name: Notification.Name(CryptoNotification.cryptoUpdatedNotification), object: nil)
    }
    
    override func viewDidAppear(){
        super.viewDidAppear()
        self.homeTopSplitView.setPosition(650, ofDividerAt: 0)
        self.barPlot?.setUpPlot()
    }
    
    func configurePortfolioSummaryTable(){
        summaryTable.delegate = self
        self.positionSummaryController.content = self.portfolio.positions
    }
    
    func configureSplitView(){
        splitview?.delegate = self
        splitview?.wantsLayer = true
        splitview?.layer?.backgroundColor = NSColor.white.cgColor
        if self.portfolio.isEmpty {
            self.splitview?.arrangedSubviews.last?.isHidden = true
        }
    }
    
    func configureValueDisplay(){
        self.marketValueLabel.formatter = CryptoFormatters.currencyFormatter
        self.marketValueLabel.objectValue =  self.portfolio.defaultMarketValue
    }
    
    @objc func priceUpdatedObserver(notification: Notification){
        DispatchQueue.main.async {
            self.summaryTable.reloadData()
            self.marketValueLabel.objectValue = self.portfolio.defaultMarketValue
            if (self.splitview?.arrangedSubviews.last?.isHidden)! && !self.portfolio.isEmpty {
                self.splitview?.arrangedSubviews.last?.isHidden = false
                self.barPlot?.refreshPlot()
            }
        }
    }
}

extension HomeViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat{
        return 25
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier.rawValue)!), owner: nil) as? NSTableCellView {
            if let columnIdentifier = tableColumn?.identifier.rawValue {
                switch(columnIdentifier){
                case "Gross Position":
                    cell.textField?.formatter = CryptoFormatters.cryptoFormatter
                default:
                    break
                }
            }
            return cell
        }
        return nil
    }
}

extension HomeViewController: GraphConfigDelegate {
    func didFinishSetUp(sender: Any) {
        if let plot = (sender as? Graph)?.plot {
            self.hostView?.hostedGraph = plot
        }
    }
    func didFinishRefresh(sender: Any) {}
}

extension HomeViewController: PortfolioUpdatedDelegate {
    func portfolioUpdated(sender: Portfolio){
        DispatchQueue.main.async {
            self.positionSummaryController.content = self.portfolio.positions
            self.summaryTable.reloadData()
            self.barPlot?.refreshPlot()
            self.configureValueDisplay()
        }
    }
}



