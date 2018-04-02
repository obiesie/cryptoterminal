//
//  OperationQueue.swift
//  cryptoterminal
//
//  Created by Obiesie Ike-Nwosu on 23/03/2018.
//  Copyright © 2018 Obiesie Ike-Nwosu. All rights reserved.
//

import Foundation

/**
 The delegate of an `OperationQueue` can respond to `Operation` lifecycle
 events by implementing these methods.
 
 In general, implementing `OperationQueueDelegate` is not necessary; you would
 want to use an `OperationObserver` instead. However, there are a couple of
 situations where using `OperationQueueDelegate` can lead to simpler code.
 For example, `GroupOperation` is the delegate of its own internal
 `OperationQueue` and uses it to manage dependencies.
 */
@objc protocol OperationQueueDelegate: NSObjectProtocol {
    @objc optional func operationQueue(operationQueue: OperationQueue, willAddOperation operation: Operation)
    @objc optional func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: Operation, withErrors errors: [NSError])
}

/**
 `OperationQueue` is an `NSOperationQueue` subclass that implements a large
 number of "extra features" related to the `Operation` class:
 
 - Notifying a delegate of all operation completion
 - Extracting generated dependencies from operation conditions
 - Setting up dependencies to enforce mutual exclusivity
 */
class CryptoOperationQueue: OperationQueue {
    weak var delegate: OperationQueueDelegate?
    
    override func addOperation(_ operation: Operation) {
        if let op = operation as? CryptoOperation {
            // Set up a `BlockObserver` to invoke the `OperationQueueDelegate` method.
            let delegate = BlockObserver(
                startHandler: nil,
                produceHandler: { [weak self] in
                    self?.addOperation($1)
                },
                finishHandler: { [weak self] in
                    if let q = self {
                        q.delegate?.operationQueue?(operationQueue: q, operationDidFinish: $0, withErrors: $1)
                    }
                }
            )
            op.addObserver(observer: delegate)
            
            // Extract any dependencies needed by this operation.
            let dependencies = op.conditions.flatMap {
                $0.dependencyForOperation(operation: op)
            }
            
            for dependency in dependencies {
                op.addDependency(dependency)
                self.addOperation(dependency)
            }
            
            /*
             Indicate to the operation that we've finished our extra work on it
             and it's now it a state where it can proceed with evaluating conditions,
             if appropriate.
             */
            op.willEnqueue()
        } else {
            /*
             For regular `NSOperation`s, we'll manually call out to the queue's
             delegate we don't want to just capture "operation" because that
             would lead to the operation strongly referencing itself and that's
             the pure definition of a memory leak.
             */
            operation.completionBlock = { [weak self, weak operation] in
                guard let queue = self, let operation = operation else { return }
                queue.delegate?.operationQueue?(operationQueue: queue, operationDidFinish: operation, withErrors: [])
            }
        }
        delegate?.operationQueue?(operationQueue: self, willAddOperation: operation)
        super.addOperation(operation)
    }
    
    override func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {
        for operation in operations {
            addOperation(operation)
        }
        
        if wait {
            for operation in operations {
                operation.waitUntilFinished()
            }
        }
    }
}
