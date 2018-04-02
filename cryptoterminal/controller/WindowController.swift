//
//  WindowController.swift
//  cryptoterminal
//


import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        window?.title = "crypto"
        window?.titlebarAppearsTransparent = true
        window?.toolbar?.showsBaselineSeparator = false
        window?.styleMask.insert(.fullSizeContentView)
        window?.backgroundColor = NSColor.white
    }
}
