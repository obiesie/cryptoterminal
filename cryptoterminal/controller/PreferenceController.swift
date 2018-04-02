//
//  PreferenceController.swift
//  cryptoterminal
//


import Cocoa

class PreferenceController: NSTabViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.tabView.delegate = self
        // Do view setup here.
        self.title = "Preferences"
        self.tabViewItems[0].image = NSImage(imageLiteralResourceName: NSImage.Name.preferencesGeneral.rawValue)
        self.tabViewItems[0].label = "General"
        //self.tabViewItems[1].image = NSImage(imageLiteralResourceName: NSImage.Name.advanced.rawValue)
        //self.tabViewItems[1].label = "Security"        
    }
}
