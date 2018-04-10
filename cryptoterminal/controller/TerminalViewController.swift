//
//  TerminalViewController.swift
//  cryptoterminal
//


import Foundation
import Cocoa


class TerminalViewController: NSSplitViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

class CustomSplitView : NSSplitView {
    
    override var dividerThickness: CGFloat { get {return 0.0} }
}
