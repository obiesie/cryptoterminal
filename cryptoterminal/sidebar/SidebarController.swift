//
//  SidebarController.swift
//  cryptoterminal
//

import Foundation
import Cocoa

class SidebarController: NSViewController {
    @IBOutlet weak var sidebarOutline: NSOutlineView!
    let icons = ["NSImage.Name.homeTemplate" : NSImage.Name.homeTemplate,
                 "NSImage.Name.revealFreestandingTemplate":NSImage.Name.revealFreestandingTemplate,
                 "NSImage.Name.folderSmart": NSImage.Name.bookmarksTemplate,
                 "NSImage.Name.smartBadgeTemplate":NSImage.Name.smartBadgeTemplate,
                 "NSImage.Name.listViewTemplate":NSImage.Name.listViewTemplate]
    var sideMenuList = [SideMenuItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let filePath = Bundle.main.path(forResource: "SideMenus", ofType: "plist") {
            sideMenuList = SideMenuItem.sideMenuList(fileName: filePath)
        }
        self.sidebarOutline.delegate = self
        self.sidebarOutline.dataSource = self
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let table = notification.object as? NSTableView,
            let tabController =  parent?.childViewControllers[1] as? NSTabViewController {
            let selectedRowIndex = table.selectedRow
            tabController.selectedTabViewItemIndex = selectedRowIndex
        }
    }
}

extension SidebarController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let sideMenuItem = item as? SideMenuItem {
            return sideMenuItem.children.count
        }
        return sideMenuList.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let sideMenuItem = item as? SideMenuItem {
            return sideMenuItem.children[index]
        }
        return sideMenuList[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let sideMenuItem = item as? SideMenuItem {
            return sideMenuItem.children.count > 0
        }
        return false
    }
}

extension SidebarController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        if let sideMenuItem = item as? SideMenuItem {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sideMenu"), owner: self) as? NSTableCellView

            if let textField = view?.textField {
                textField.stringValue = sideMenuItem.name
                view?.imageView!.image = NSImage(named: icons[sideMenuItem.icon]!)
            }
        }
        return view
    }
    
    func outlineView(_ outlineView: NSOutlineView,
                     heightOfRowByItem item: Any) -> CGFloat{
        return 30.0
    }
}
