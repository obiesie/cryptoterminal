//
//  ResultContext.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 24/03/2018.
//  Copyright © 2018 Obiesie Ike-Nwosu. All rights reserved.
//

import Foundation

class OperationResultContext {
    var data: [[ String : Any ]] {
        set {
            lock.lock()
            _data = newValue
            lock.unlock()
        }
        get {
            lock.lock()
            let result =  _data
            lock.unlock()
            return result
        }
    }
    
    private var _data: [[ String : Any ]] = []
    private let lock = NSLock()
}

