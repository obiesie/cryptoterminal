//
//  MouseMovedAwareCPTGraphHostingView.swift
//  cryptoterminal
//

import Cocoa
import CorePlot


class MouseMovedAwareCPTGraphHostingView: CPTGraphHostingView {
    
    var trackingArea : NSTrackingArea?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func updateTrackingAreas() {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea!)
        }
        let options : NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp, .mouseMoved ]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options,
                                      owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        delegate?.mouseMovedInGraphArea(with: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        delegate?.mouseExitedGraphArea(with: event)
    }
    weak var delegate:MouseMovedAwareCPTGraphHostingViewDelegate?
    
}

protocol MouseMovedAwareCPTGraphHostingViewDelegate: class {
    func mouseMovedInGraphArea(with event: NSEvent)
    func mouseExitedGraphArea(with event: NSEvent)
}

