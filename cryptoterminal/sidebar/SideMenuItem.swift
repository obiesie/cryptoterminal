//
//  Feed.swift
//  cryptoterminal
//

import Cocoa

class SideMenuItem: NSObject {
    let icon: String
    let name: String
    var children = [SubSidemenuItem]()
    
    init(name: String, icon: String) {
        self.name = name
        self.icon = icon
    }
    
    class func sideMenuList(fileName: String) -> [SideMenuItem] {
        var sideMenus = [SideMenuItem]()
        if let sideMenuList = NSArray(contentsOfFile: fileName) as? [NSDictionary] {
            for sideMenu in sideMenuList {
                let feed = SideMenuItem(name: sideMenu.object(forKey: "name") as! String, icon: sideMenu.object(forKey: "icon") as! String)
                sideMenus.append(feed)
            }
        }
        return sideMenus
    }
}

class SubSidemenuItem: NSObject {}

