//
//  URLSessionTaskOperation.swift
//  cryptoterminal
//


import Foundation

private var URLSessionTaksOperationKVOContext = 0

class URLSessionTaskOperation: BasicOperation {
   
    let task: URLSessionTask
    
    init(task: URLSessionTask) {
        assert(task.state == .suspended, "Tasks must be suspended.")
        self.task = task
        super.init()
    }
    
    override func main() {
        assert(task.state == .suspended, "Task was resumed by something other than \(self).")
        task.addObserver(self, forKeyPath: "state", options: [], context: &URLSessionTaksOperationKVOContext)
        task.resume()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &URLSessionTaksOperationKVOContext,
            let obj = object as? URLSessionTask
            else { return }
        
        if obj == task && keyPath == "state" && task.state == .completed {
            finish( true )
            task.removeObserver(self, forKeyPath: "state")
        }
    }
    
    override func cancel() {
        task.cancel()
        super.cancel()
    }
}
