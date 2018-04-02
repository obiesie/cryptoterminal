//
//  Observer.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 23/03/2018.
//  Copyright © 2018 Obiesie Ike-Nwosu. All rights reserved.
//

import Foundation

/**
 The protocol that types may implement if they wish to be notified of significant
 operation lifecycle events.
 */
protocol OperationObserver {
    
    /// Invoked immediately prior to the `Operation`'s `execute()` method.
    func operationDidStart(operation: Operation)
    
    /// Invoked when `Operation.produceOperation(_:)` is executed.
    func operation(operation: Operation, didProduceOperation newOperation: Operation)
    
    /**
     Invoked as an `Operation` finishes, along with any errors produced during
     execution (or readiness evaluation).
     */
    func operationDidFinish(operation: Operation, errors: [NSError])
    
}


/**
 The `BlockObserver` is a way to attach arbitrary blocks to significant events
 in an `Operation`'s lifecycle.
 */
struct BlockObserver: OperationObserver {
    // MARK: Properties
    
    private let startHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Operation) -> Void)?
    private let finishHandler: ((Operation, [NSError]) -> Void)?
    
    init(startHandler: ((Operation) -> Void)? = nil, produceHandler: ((Operation, Operation) -> Void)? = nil, finishHandler: ((Operation, [NSError]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    func operationDidStart(operation: Operation) {
        startHandler?(operation)
    }
    
    func operation(operation: Operation, didProduceOperation newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    func operationDidFinish(operation: Operation, errors: [NSError]) {
        finishHandler?(operation, errors)
    }
}

