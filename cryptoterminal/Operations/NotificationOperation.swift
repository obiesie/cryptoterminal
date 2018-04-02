//
//  NotificationOperation.swift
//  cryptoterminal
//


import Foundation

class NotificationOperation : BasicOperation {
    
    let notification : String
    
    init(notification : String){
        self.notification = notification
    }
    
    override func main() {
        NotificationCenter.default.post(name: Notification.Name(notification), object: nil)
        finish(true)
    }
}
