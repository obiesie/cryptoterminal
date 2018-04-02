//
//  FeedItem.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 6/23/17.
//  Copyright © 2017 Obiesie Ike-Nwosu. All rights reserved.
//

import Cocoa

class FeedItem: NSObject {
    
    let url: String
    let title: String
    let publishingDate: Date
    
    init(dictionary: NSDictionary) {
        self.url = dictionary.object(forKey: "url") as! String
        self.title = dictionary.object(forKey: "title") as! String
        self.publishingDate = dictionary.object(forKey: "date") as! Date
    }

}
