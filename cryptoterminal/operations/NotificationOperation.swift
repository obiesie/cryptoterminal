//
//  NotificationOperation.swift
//  cryptoterminal
//


import Foundation

class NotificationOperation : CryptoOperation {
    
    let notification : String
    
    init(notification : String){
        self.notification = notification
    }
    
    override func execute() {
        NotificationCenter.default.post(name: Notification.Name(notification), object: nil)
        finish(errors: [])
    }
}
