//
//  WatchListDataResolver.swift
//  cryptoterminal
//

import CorePlot
import Foundation

protocol WatchList {
    func exchangeRates(for pair: CurrencyPair, since time : TimeInterval) -> [HistoricalExchangeRate]
    func watchListedItems() -> [CurrencyPair]
}


protocol GraphConfig : CPTPlotDelegate {
    var plot: CPTXYGraph { get }
    var delegate:GraphConfigDelegate? { get set }

    func setUpPlot(for period: String, using dataPoints : [HistoricalExchangeRate], usingFormatter formatter : NumberFormatter?)
    func refreshPlot(for period: String, using data: [HistoricalExchangeRate], usingFormatter formatter : NumberFormatter?)
}

struct ScatterPlotProperties {
    
    let ticks: Set<NSNumber>
    let axisLabels: Set<CPTAxisLabel>
    let histLimit : Int
    let numberOfTicks = 10
    let labelOffset : CGFloat = 5.0
    let yDataPoints = [Double]()
    let xDataPoints = [Int]()
    let plotData : [HistoricalExchangeRate]
    
    let maxYDataPoint : Double
    let minYDataPoint : Double
    let maxXDataPoint : Int
    let minXDataPoint : Int
    let yMajorIntervalLength : Float
    let xMajorIntervalLength : Int
    
    
    init(graphData : [HistoricalExchangeRate], histLimits : Int, maxYDataPoint:Double, minYDataPoint:Double, maxXDataPoint:Int, minXDataPoint:Int,
         yMajorIntervalLength:Float, xMajorIntervalLength:Int, ticks: Set<NSNumber>,  axisLabels: Set<CPTAxisLabel>){
        self.plotData = graphData
        self.histLimit = histLimits
        self.maxXDataPoint = maxXDataPoint
        self.minYDataPoint = minYDataPoint
        self.maxYDataPoint = maxYDataPoint
        self.minXDataPoint = minXDataPoint
        self.yMajorIntervalLength = yMajorIntervalLength
        self.xMajorIntervalLength = xMajorIntervalLength
        self.ticks = ticks
        self.axisLabels = axisLabels
    }
}

protocol GraphConfigDelegate: class {
    func didFinishSetUp(sender: Any)
    func didFinishRefresh(sender: Any)
}

class ScatterGraphConfig : NSObject, GraphConfig, CPTPlotDataSource, CPTPlotDelegate {
    
    var plot : CPTXYGraph {
        get {
            return self._plot!
        }
    }
    var _plot: CPTXYGraph?
    static let numberOfTicks = 10
    static let labelOffset : CGFloat = 5.0
    var dataPoints = [HistoricalExchangeRate]()
    weak var delegate:GraphConfigDelegate?
    var priceAnnotation: CPTPlotSpaceAnnotation?
    var verticalCrossHair: CPTXYAxis?
    private var xminimum : Double = 0.0
    private var yinterval : CGFloat = 0.0
    
    static var textStyle: CPTMutableTextStyle {
        let textStyle = CPTMutableTextStyle()
        textStyle.color = CPTColor.black()
        textStyle.fontName = "Lato"
        textStyle.fontSize = 10.0
        textStyle.textAlignment = .center
        return textStyle
    }
    static var axisLineStyle : CPTMutableLineStyle{
        let axisLineStyle = CPTMutableLineStyle()
        axisLineStyle.lineWidth = 0.5
        axisLineStyle.lineColor = .lightGray()
        return axisLineStyle
    }
    
    static var graphAxisDateTimeFormatter : CPTTimeFormatter {
        let timeFormatter = CPTTimeFormatter(dateFormatter:CryptoFormatters.dateFormatter)
        timeFormatter.referenceDate = Date(timeIntervalSince1970: 0.0)
        return timeFormatter
    }
    
    static var scatterPlotLinestyle : CPTMutableLineStyle {
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth              = GraphConstants.SCATTER_PLOT_LINE_WIDTH
        lineStyle.lineColor              = GraphConstants.SCATTER_PLOT_LINE_COLOR
        return lineStyle
    }
    
    override init(){
        super.init()
    }
    
    func setUpPlot(for period: String, using dataPoints : [HistoricalExchangeRate], usingFormatter formatter : NumberFormatter?){
        self.dataPoints = dataPoints
        let properties = self.computeGraphProperties(for: period, usingFormatter: formatter)
        self.setUpGraphContainer(using: properties)
        delegate?.didFinishSetUp(sender: self)
    }
    
    func refreshPlot(for period: String, using data: [HistoricalExchangeRate], usingFormatter formatter : NumberFormatter?) {
        self.dataPoints = data
        if let properties = computeGraphProperties(for: period, usingFormatter: formatter) {
            DispatchQueue.main.async {
                self.setupGraphBounds(using: properties)
                self._plot?.reloadData()
                self.delegate?.didFinishRefresh(sender: self)
            }
        }
    }
    
    func numberOfRecords(for plot: CPTPlot) -> UInt    {
        return UInt(self.dataPoints.count)
    }
    
    func number(for plot: CPTPlot, field: UInt, record: UInt) -> Any?{
        switch CPTScatterPlotField(rawValue: Int(field))! {
        case .X:
            return self.dataPoints[Int(record)].time
        case .Y:
            return self.dataPoints[Int(record)].close as NSNumber
        }
    }
    
    private func computeGraphProperties(for period: String, usingFormatter formatter : NumberFormatter?) -> ScatterPlotProperties? {
        
        guard !self.dataPoints.isEmpty else { return nil }
        let plotData = self.sampleDataFor(period: period, data: self.dataPoints)
        
        let yDataPoints = plotData.map{(p: HistoricalExchangeRate) -> Double in return p.close }
        let xDataPoints = plotData.map{(p: HistoricalExchangeRate) -> Int in return p.time}
        
        guard let maxYDataPoint = yDataPoints.max(), let minYDataPoint = yDataPoints.min(),
            let maxXDataPoint = xDataPoints.max(), let minXDataPoint = xDataPoints.min()
            else { return nil}
        
        let xRange = maxXDataPoint - minXDataPoint
        let yRange = maxYDataPoint - minYDataPoint
        
        let yMajorIntervalLength = Float(yRange)/Float(ScatterGraphConfig.numberOfTicks)
        let xMajorIntervalLength = Int(xRange)/ScatterGraphConfig.numberOfTicks
        var ticks = Set<NSNumber>()
        var axisLabels = Set<CPTAxisLabel>()
        for i in stride(from:minYDataPoint, through:maxYDataPoint, by: Double(yMajorIntervalLength)) {
            let tickString = CryptoFormatters.decimalFormatter.string(from: NSNumber(value: i))
            let tick = CryptoFormatters.decimalFormatter.number(from: tickString!)
            let label = CPTAxisLabel(text: formatter?.string(from: NSNumber(value:i)) ?? tickString,
                                     textStyle: ScatterGraphConfig.textStyle)
            label.tickLocation = i as NSNumber
            label.offset = ScatterGraphConfig.labelOffset
            label.alignment = .left
            ticks.insert(tick!)
            axisLabels.insert(label)
        }
        if !ticks.contains(maxYDataPoint as NSNumber){
            let tickString = CryptoFormatters.decimalFormatter.string(from: NSNumber(value: maxYDataPoint))
            let tick = CryptoFormatters.decimalFormatter.number(from: tickString!)
            let label = CPTAxisLabel(text: formatter?.string(from: NSNumber(value: maxYDataPoint)) ?? tickString,
                                     textStyle: ScatterGraphConfig.textStyle)
            label.offset = ScatterGraphConfig.labelOffset
            label.tickLocation = tick!
            label.alignment = .left
            ticks.insert(tick!)
            axisLabels.insert(label)
        }
        
        return ScatterPlotProperties(graphData:plotData, histLimits:plotData.count,
                                     maxYDataPoint:maxYDataPoint, minYDataPoint:minYDataPoint,
                                     maxXDataPoint:maxXDataPoint, minXDataPoint:minXDataPoint,
                                     yMajorIntervalLength:yMajorIntervalLength,xMajorIntervalLength:xMajorIntervalLength,
                                     ticks:ticks, axisLabels:axisLabels)
    }
    
    private func setUpGraphContainer(using graphProperties:ScatterPlotProperties?){
        
        self._plot = CPTXYGraph(frame:.zero)
        self._plot?.paddingLeft = GraphConstants.GRAPH_PADDING_LEFT
        self._plot?.paddingTop = GraphConstants.GRAPH_PADDING_TOP
        self._plot?.paddingRight = GraphConstants.GRAPH_PADDING_RIGHT
        self._plot?.paddingBottom = GraphConstants.GRAPH_PADDING_BOTTOM
        
        self._plot?.titleTextStyle = ScatterGraphConfig.textStyle
        self._plot?.titlePlotAreaFrameAnchor = CPTRectAnchor.top
        self._plot?.backgroundColor = CGColor.white
        
        self._plot?.plotAreaFrame?.masksToBorder = false;
        self._plot?.plotAreaFrame?.borderLineStyle = nil
        self._plot?.plotAreaFrame?.cornerRadius = GraphConstants.PLOT_FRAME_AREA_CORNER_RADIUS
        self._plot?.plotAreaFrame?.paddingTop = GraphConstants.PLOT_FRAME_AREA_PADDING_TOP
        self._plot?.plotAreaFrame?.paddingLeft = GraphConstants.PLOT_FRAME_AREA_PADDING_LEFT
        self._plot?.plotAreaFrame?.paddingBottom = GraphConstants.PLOT_FRAME_AREA_PADDING_BOTTOM
        self._plot?.plotAreaFrame?.paddingRight = GraphConstants.PLOT_FRAME_AREA_PADDING_RIGHT
        
        let linePlot = CPTScatterPlot(frame: .zero)
        linePlot.dataLineStyle = ScatterGraphConfig.scatterPlotLinestyle
        linePlot.dataSource = self
        
        self._plot?.add(linePlot)
        if let properties = graphProperties {
            setupGraphBounds(using: properties)
        }
    }
    
    func setupGraphBounds(using properties : ScatterPlotProperties){
        if let plotSpace = self._plot?.defaultPlotSpace as? CPTXYPlotSpace {
            
            let xRange = properties.maxXDataPoint - properties.minXDataPoint
            let yRange = properties.maxYDataPoint - properties.minYDataPoint
            
            plotSpace.xRange = CPTPlotRange(location:properties.minXDataPoint as NSNumber, length:xRange as NSNumber)
            plotSpace.yRange = CPTPlotRange(location:properties.minYDataPoint as NSNumber, length:yRange as NSNumber)
            
            guard let axisSet = self._plot?.axisSet as? CPTXYAxisSet else { return }
            if let xAxis = axisSet.xAxis {
                xAxis.majorIntervalLength = properties.xMajorIntervalLength as NSNumber
                xAxis.orthogonalPosition = properties.minYDataPoint as NSNumber
                xAxis.labelTextStyle = ScatterGraphConfig.textStyle
                xAxis.labelFormatter  = ScatterGraphConfig.graphAxisDateTimeFormatter
                xAxis.axisLineStyle = ScatterGraphConfig.axisLineStyle
                xAxis.visibleAxisRange = CPTPlotRange(location: properties.minXDataPoint as NSNumber, length: xRange as NSNumber)
            }
            if let yAxis = axisSet.yAxis {
                yAxis.labelingPolicy = .none
                yAxis.majorIntervalLength   = properties.yMajorIntervalLength as NSNumber
                yAxis.orthogonalPosition    = properties.minXDataPoint as NSNumber
                yAxis.labelTextStyle = ScatterGraphConfig.textStyle
                yAxis.labelFormatter = CryptoFormatters.decimalFormatter
                yAxis.axisLineStyle = ScatterGraphConfig.axisLineStyle
                yAxis.majorGridLineStyle = ScatterGraphConfig.axisLineStyle
                yAxis.majorTickLineStyle = ScatterGraphConfig.axisLineStyle
                yAxis.majorTickLocations = properties.ticks
                yAxis.axisLabels = properties.axisLabels
                yAxis.gridLinesRange = CPTPlotRange(location:properties.minXDataPoint as NSNumber, length:xRange as NSNumber)
            }
        }
    }
    
    private func sampleDataFor(period : String, data : [HistoricalExchangeRate] ) -> [HistoricalExchangeRate] {
        var sampledData = [HistoricalExchangeRate]()
        if let p = period.last,
            let periodNumericForm = Int(period.dropLast()) {
            let maxHistoricalRatesCount = periodToMinutes(period: period)
            let t = data.count < maxHistoricalRatesCount ? data.count : maxHistoricalRatesCount
            
            sampledData = Array( data[0..<t] )
            if p == "D" {
                let historicalRatesCount = self.dataPoints.count < maxHistoricalRatesCount ? self.dataPoints.count : maxHistoricalRatesCount
                sampledData = stride(from: 0, to: historicalRatesCount, by: periodNumericForm*2).map { self.dataPoints[$0] }
            }
        }
        return sampledData
    }
}


class SimpleWatchList : WatchList {

    let currencyPairRepo : CurrencyPairRepo
    let exchangeRateRepo: ExchangeRateRepo
    
    private var lastSetOfExchangeRates = [HistoricalExchangeRate]()
    private var lastCurrencyPair : CurrencyPair?
    
    init(currencyPairRepo:CurrencyPairRepo, exchangeRateRepo:ExchangeRateRepo){
        self.currencyPairRepo = currencyPairRepo
        self.exchangeRateRepo = exchangeRateRepo
    }
    
    func watchListedItems() -> [CurrencyPair] {
        return currencyPairRepo.watchListedCurrencyPairs()
    }
    
    func exchangeRates(for pair: CurrencyPair, since time: TimeInterval) -> [HistoricalExchangeRate] {
        let maxRateDataPoints = 10080
        if dataIsCachedForPair(pair: pair) {
            let newRates = self.exchangeRateRepo.exchangeRates(for: pair, after: time)
            lastSetOfExchangeRates.insert(contentsOf: newRates, at: 0)
            if self.lastSetOfExchangeRates.count > maxRateDataPoints {
                self.lastSetOfExchangeRates.removeSubrange(maxRateDataPoints..<self.lastSetOfExchangeRates.endIndex)
            }
        } else {
            self.lastSetOfExchangeRates = exchangeRateRepo.exchangeRates(for: pair)
        }
        return lastSetOfExchangeRates
    }
    
    private func dataIsCachedForPair(pair:CurrencyPair) -> Bool {
        if let last = lastCurrencyPair,
            pair.baseCurrencyId == last.baseCurrencyId && pair.denominatedCurrencyId == last.denominatedCurrencyId, !self.lastSetOfExchangeRates.isEmpty {
            return true
        }
        return false
    }
}

extension ScatterGraphConfig: MouseMovedAwareCPTGraphHostingViewDelegate {
    
    func mouseExitedGraphArea(with event: NSEvent) {
        priceAnnotation?.annotationHostLayer?.removeAnnotation(priceAnnotation)
        if let axisCount = _plot?.axisSet?.axes?.count, axisCount > 2 {
            _plot?.axisSet?.axes?.remove(at: axisCount - 1)
        }
    }
    
    func mouseMovedInGraphArea(with event: NSEvent) {
        guard !self.dataPoints.isEmpty else {
            return
        }
        let plot = (self._plot?.allPlots().last as! CPTScatterPlot)
        let plotPoint = plot.plotSpace?.plotPoint(for: event)
        
        priceAnnotation?.annotationHostLayer?.removeAnnotation(priceAnnotation)
        if let axisCount = _plot?.axisSet?.axes?.count, axisCount > 2 {
            _plot?.axisSet?.axes?.removeLast()
        }
        
        let plotCGPoint = plot.plotSpace?.plotAreaViewPoint(for: event)
        let dataIndex = plot.indexOfVisiblePointClosest(toPlotAreaPoint: plotCGPoint!)
        let chosenData = self.dataPoints[Int(dataIndex)]
        
        let annotationPriceDisplay = chosenData.close
        let annotationTimeDisplay = CryptoFormatters.longDateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(chosenData.time)))
        
        let textLayer = CPTTextLayer(text:"\(annotationPriceDisplay) \n \(annotationTimeDisplay)", style: ScatterGraphConfig.textStyle)
        textLayer.borderColor   = NSColor.gray.cgColor
        textLayer.borderWidth   = 0.5
        textLayer.backgroundColor = .white
        textLayer.paddingLeft   = 2.0
        textLayer.paddingTop    = 2.0
        textLayer.paddingRight  = 2.0
        textLayer.paddingBottom = 2.0
        
        priceAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace!, anchorPlotPoint: [0, 0])
        priceAnnotation?.contentLayer = textLayer
        
        // postion of annotation
        let anchorPoint = [NSNumber(cgFloat: CGFloat(chosenData.time)), NSNumber(cgFloat:CGFloat(chosenData.close) - yinterval) ]
        priceAnnotation?.anchorPlotPoint = anchorPoint
        
        guard let plotArea = _plot?.plotAreaFrame?.plotArea else {
            return
        }
        plotArea.addAnnotation(priceAnnotation)
        
        verticalCrossHair = CPTXYAxis()
        verticalCrossHair?.axisLineStyle = ScatterGraphConfig.axisLineStyle
        verticalCrossHair?.coordinate = .Y
        verticalCrossHair?.plotSpace = _plot?.defaultPlotSpace
        verticalCrossHair?.labelingPolicy = .none
        verticalCrossHair?.orthogonalPosition    = plotPoint![0] as NSNumber
        verticalCrossHair?.labelFormatter = CryptoFormatters.decimalFormatter
        verticalCrossHair?.axisLineStyle = ScatterGraphConfig.axisLineStyle
        verticalCrossHair?.majorTickLocations = nil
        
        _plot?.axisSet?.axes?.append(verticalCrossHair!)
    }
}

