//
//  Graph.swift
//  cryptoterminal
//


import CorePlot
import Foundation

protocol Graph {
    
    weak var delegate:GraphConfigDelegate? { get set }
    var plot : CPTXYGraph { get set }
    func setUpPlot()
    func refreshPlot()
}

class PortfolioChart : NSObject, CPTPlotDelegate {
    
    private override init(){
        super.init()
    }
    
    static func portfolioChart(from  portfolio:Portfolio) -> Graph {
        return portfolio.assetCollection.count > 8 ? VerticalBarGraph(using: portfolio) : HorizontalBarGraph(using: portfolio)
    }
}

private class BarGraph : NSObject, CPTPlotDataSource, CPTPlotDelegate, Graph{
    
    var plot: CPTXYGraph
    var portfolio : Portfolio
    weak var delegate:GraphConfigDelegate?
    var priceAnnotation: CPTPlotSpaceAnnotation?
    var BarWidth : Double { return 0.3 }
    var BarInitialX : Double { return 0.25 }
    var titleStyle : CPTMutableTextStyle {
        let _titleStyle = CPTMutableTextStyle()
        _titleStyle.color = CPTColor.black()
        _titleStyle.fontName = "Lato"
        _titleStyle.fontSize = 14.0
        _titleStyle.textAlignment = .center
        return _titleStyle
    }
    
    var axesTitleStyle : CPTMutableTextStyle {
        let _axesTitleStyle = CPTMutableTextStyle()
        _axesTitleStyle.color = CPTColor.black()
        _axesTitleStyle.fontName = "Lato"
        _axesTitleStyle.fontSize = 12.0
        _axesTitleStyle.textAlignment = .center
        return _axesTitleStyle
    }
    var axisLineStyle : CPTMutableLineStyle {
        let _axisLineStyle = CPTMutableLineStyle()
        _axisLineStyle.lineWidth = 0.5
        _axisLineStyle.lineColor = .gray()
        return _axisLineStyle
    }
    
    init(using portfolio : Portfolio){
        self.portfolio = portfolio
        self.plot = CPTXYGraph(frame: .zero)
        super.init()
    }
    
    func setUpPlot(){
        configureGraph()
        configureBars()
        configureAxes()
        self.delegate?.didFinishSetUp(sender: self)
    }
    
    func refreshPlot(){
        self.configureGraph()
        self.plot.reloadData()
    }
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(portfolio.positions.count)
        
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        if fieldEnum == UInt(CPTBarPlotField.barTip.rawValue){
            let assetMarketValue = portfolio.positions[Int(idx)].defaultMarketValue
            let portfolioMarketValue = self.portfolio.defaultMarketValue
            return assetMarketValue/portfolioMarketValue
        }
        return idx;
    }
    
    func configureGraph() {
        self.plot = CPTXYGraph(frame: .zero)
        plot.plotAreaFrame?.masksToBorder = false
        
        // 2 - Configure the graph
        plot.fill = CPTFill(color: CPTColor.clear())
        
        plot.paddingLeft = GraphConstants.GRAPH_PADDING_LEFT
        plot.paddingTop = GraphConstants.GRAPH_PADDING_TOP
        plot.paddingRight = GraphConstants.GRAPH_PADDING_RIGHT
        plot.paddingBottom = GraphConstants.GRAPH_PADDING_BOTTOM
        
        plot.titlePlotAreaFrameAnchor = CPTRectAnchor.top
        plot.backgroundColor = CGColor.white
        
        plot.plotAreaFrame?.masksToBorder = false
        plot.plotAreaFrame?.borderLineStyle = nil
        plot.plotAreaFrame?.cornerRadius = GraphConstants.PLOT_FRAME_AREA_CORNER_RADIUS
        plot.plotAreaFrame?.paddingTop = GraphConstants.PLOT_FRAME_AREA_PADDING_TOP
        plot.plotAreaFrame?.paddingLeft = GraphConstants.PLOT_FRAME_AREA_PADDING_LEFT
        plot.plotAreaFrame?.paddingBottom = GraphConstants.PLOT_FRAME_AREA_PADDING_BOTTOM
        plot.plotAreaFrame?.paddingRight = GraphConstants.PLOT_FRAME_AREA_PADDING_RIGHT
        
        // 3 - Set up styles
        plot.titleTextStyle = titleStyle
        plot.title = "Portfolio breakdown"
        plot.titlePlotAreaFrameAnchor = .top
        plot.titleDisplacement = CGPoint(x: 0.0, y: -16.0)
    }
    
    func setUpAnnotations(_ plot: CPTBarPlot, for portfolio: Portfolio){}
    
    func configureBars() {}
    
    func configureAxes(){}
}


private class VerticalBarGraph : BarGraph {
    
    override func setUpAnnotations(_ plot: CPTBarPlot, for portfolio: Portfolio){
        guard let plotArea = plot.graph?.plotAreaFrame?.plotArea else { return }
        for annotation in plotArea.annotations {
            annotation.annotationHostLayer?.removeAnnotation(annotation)
        }
        for (index, _) in portfolio.assetCollection.enumerated(){
            
            let style = CPTMutableTextStyle()
            style.fontSize = 10.0
            style.fontName = "Lato"
            let priceAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace!, anchorPlotPoint: [0, 0])
            guard let price = number(for: plot,
                                     field: UInt(CPTBarPlotField.barTip.rawValue),
                                     record: UInt(index)) as? NSNumber else { return }
            
            let priceValue = CryptoFormatters.percentFormatter.string(from: NSNumber(cgFloat: CGFloat(truncating: price)))
            let textLayer = CPTTextLayer(text: priceValue, style: style)
            priceAnnotation.contentLayer = textLayer
            
            let x = CGFloat(index)
            let y = CGFloat(truncating: price) + 0.025
            priceAnnotation.anchorPlotPoint = [NSNumber(cgFloat: x), NSNumber(cgFloat: y)]
            
            // guard let plotArea = plot.graph?.plotAreaFrame?.plotArea else { return }
            plotArea.addAnnotation(priceAnnotation)
        }
    }
    
    
    override func configureBars() {
        let barPlot = CPTBarPlot()
        barPlot.fill = CPTFill(color: CPTColor(componentRed:0.92, green:0.28, blue:0.25, alpha:1.00))
        let barLineStyle = CPTMutableLineStyle()
        barLineStyle.lineColor = CPTColor.lightGray()
        barLineStyle.lineWidth = 0.5
        
        barPlot.dataSource = self
        barPlot.delegate = self
        barPlot.barWidth = NSNumber(value: BarWidth)
        barPlot.lineStyle = barLineStyle
        plot.add(barPlot, to: plot.defaultPlotSpace)
        
        setUpAnnotations(barPlot, for: portfolio)
    }
    
    override func configureAxes(){
        guard let axisSet = plot.axisSet as? CPTXYAxisSet else { return }
        
        let xMin = 0.0
        let xMax = Double(portfolio.assetCollection.count)
        let yMin = 0.0
        let yMax = 1.0
        guard let plotSpace = plot.defaultPlotSpace as? CPTXYPlotSpace else { return }
        plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(0.0), lengthDecimal: CPTDecimalFromDouble(yMax - yMin))
        plotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(-1.0), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
        
        if let yAxis = axisSet.yAxis {
            yAxis.orthogonalPosition = -0.5
            
            yAxis.labelingPolicy = .none
            yAxis.axisLineStyle = axisLineStyle
            var majorTickLocations = Set<NSNumber>()
            var axisLabels = Set<CPTAxisLabel>()
            for value in stride(from: 0, to: 1.1, by: 0.1) {
                majorTickLocations.insert(value as NSNumber)
                let label = CPTAxisLabel(text: "\( CryptoFormatters.decimalFormatter.string(from: value as NSNumber)! )", textStyle: axesTitleStyle)
                label.tickLocation = NSNumber(value: value)
                label.offset = 5.0
                label.alignment = .center
                axisLabels.insert(label)
            }
            yAxis.majorTickLocations = majorTickLocations
            yAxis.axisLabels = axisLabels
            let portfolioAssetCount = portfolio.assetCollection.count
            yAxis.gridLinesRange = CPTPlotRange(location:0.0 as NSNumber, length: portfolioAssetCount as NSNumber)
            yAxis.visibleAxisRange = CPTPlotRange(location:0.0 as NSNumber, length:portfolioAssetCount as NSNumber)
        }
        
        if let xAxis = axisSet.xAxis {
            xAxis.labelingPolicy = .none
            xAxis.axisLineStyle = axisLineStyle
            
            var majorTickLocations = Set<NSNumber>()
            var axisLabels = Set<CPTAxisLabel>()
            
            for (idx, asset) in portfolio.assetCollection.enumerated() {
                majorTickLocations.insert(idx as NSNumber)
                let label = CPTAxisLabel(text: "\(asset.code)", textStyle: axesTitleStyle)
                label.tickLocation = NSNumber(value: idx)
                label.offset = 0.0
                label.alignment = .center
                axisLabels.insert(label)
            }
            xAxis.majorTickLocations = majorTickLocations
            xAxis.axisLabels = axisLabels
        }
    }
}


private class HorizontalBarGraph : BarGraph {
    
    override func setUpAnnotations(_ plot: CPTBarPlot, for portfolio: Portfolio){
        guard let plotArea = plot.graph?.plotAreaFrame?.plotArea else { return }
        for annotation in plotArea.annotations {
            annotation.annotationHostLayer?.removeAnnotation(annotation)
        }
        for (index, _) in portfolio.assetCollection.enumerated(){
            
            let style = CPTMutableTextStyle()
            style.fontSize = 10.0
            style.fontName = "Lato"
            let priceAnnotation = CPTPlotSpaceAnnotation(plotSpace: plot.plotSpace!, anchorPlotPoint: [0, 0])
            guard let price = number(for: plot,
                                     field: UInt(CPTBarPlotField.barTip.rawValue),
                                     record: UInt(index)) as? NSNumber else { return }
            
            let priceValue = CryptoFormatters.percentFormatter.string(from: NSNumber(cgFloat: CGFloat(truncating: price)))
            let textLayer = CPTTextLayer(text: priceValue, style: style)
            priceAnnotation.contentLayer = textLayer
            
            let x = CGFloat(index)
            let y = CGFloat(truncating: price) + 0.025
            priceAnnotation.anchorPlotPoint = [NSNumber(cgFloat: y), NSNumber(cgFloat: x)]
            
            plotArea.addAnnotation(priceAnnotation)
        }
    }
    
    
    override func configureBars() {
        let barPlot = CPTBarPlot()
        barPlot.fill = CPTFill(color: CPTColor(componentRed:0.92, green:0.28, blue:0.25, alpha:1.00))
        barPlot.barsAreHorizontal = true
        
        let barLineStyle = CPTMutableLineStyle()
        barLineStyle.lineColor = CPTColor.lightGray()
        barLineStyle.lineWidth = 0.5
        
        barPlot.dataSource = self
        barPlot.delegate = self
        barPlot.barWidth = NSNumber(value: BarWidth)
        barPlot.lineStyle = barLineStyle
        plot.add(barPlot, to: plot.defaultPlotSpace)
        
        // for (index, _) in portfolio.assetCollection.enumerated(){
        setUpAnnotations(barPlot, for: portfolio)
        // }
        
    }
    
    override func configureAxes(){
        guard let axisSet = plot.axisSet as? CPTXYAxisSet, let plotSpace = plot.defaultPlotSpace as? CPTXYPlotSpace else { return }
        
        let xMin = -1.0
        let xMax = Double(portfolio.assetCollection.count)
        let yMin = 0.0
        let yMax = 1.0
        
        plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(xMin), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
        plotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(yMin), lengthDecimal: CPTDecimalFromDouble(yMax - yMin))
        if let yAxis = axisSet.yAxis {
            yAxis.labelingPolicy = .none
            yAxis.axisLineStyle = axisLineStyle
            var majorTickLocations = Set<NSNumber>()
            var axisLabels = Set<CPTAxisLabel>()
            for (idx, asset) in portfolio.assetCollection.enumerated() {
                majorTickLocations.insert(idx as NSNumber)
                let label = CPTAxisLabel(text: "\(asset.code)", textStyle: axesTitleStyle)
                label.tickLocation = NSNumber(value: idx)
                label.offset = 5.0
                label.alignment = .center
                axisLabels.insert(label)
            }
            yAxis.majorTickLocations = majorTickLocations
            yAxis.axisLabels = axisLabels
            let portfolioAssetCount = portfolio.assetCollection.count
            yAxis.gridLinesRange = CPTPlotRange(location:-0.5 as NSNumber, length: portfolioAssetCount as NSNumber)
            yAxis.visibleAxisRange = CPTPlotRange(location:-0.5 as NSNumber, length:portfolioAssetCount as NSNumber)
        }
        
        // 4 - Configure the y-axis
        if let xAxis = axisSet.xAxis {
            xAxis.orthogonalPosition = -0.5
            xAxis.labelingPolicy = .none
            xAxis.axisLineStyle = axisLineStyle
            var majorTickLocations = Set<NSNumber>()
            var axisLabels = Set<CPTAxisLabel>()
            for value in stride(from: 0, to: 1.1, by: 0.1) {
                majorTickLocations.insert(value as NSNumber)
                let label = CPTAxisLabel(text: "\( CryptoFormatters.decimalFormatter.string(from: value as NSNumber)! )", textStyle: axesTitleStyle)
                label.tickLocation = NSNumber(value: value)
                label.offset = 5.0
                label.alignment = .center
                axisLabels.insert(label)
            }
            xAxis.majorTickLocations = majorTickLocations
            xAxis.axisLabels = axisLabels
        }
    }
}

