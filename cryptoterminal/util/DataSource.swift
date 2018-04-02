//
//  DataSource.swift
//  cryptoterminal
//

import os
import Foundation
import GRDB

class Datasource : NSObject {
    
    let APP_DATA_DIR = "CryptoMachines"
    let APP_DB_FILE = "db.sqlite"
    
    var db : DatabaseQueue?
    var config = Configuration()
    static let shared = Datasource()
    
    private override init(){
        super.init()
        config.foreignKeysEnabled = true
        config.trace = { os_log("%@", log: OSLog.default, type: .default, $0) }
        
        let libDirectoryUrl = FileManager.default.urls(for: .libraryDirectory, in:.userDomainMask).first!
        let appLibDirectoryUrl = libDirectoryUrl.appendingPathComponent(APP_DATA_DIR)
        let dbPath = appLibDirectoryUrl.appendingPathComponent(APP_DB_FILE)
        
        os_log("The database url for the application is %@", log: OSLog.default, type: .default, dbPath.absoluteString)
        if (!FileManager.default.fileExists(atPath: dbPath.path)) {
            try! FileManager.default.createDirectory(at:appLibDirectoryUrl, withIntermediateDirectories:true, attributes: nil)
            FileManager.default.createFile(atPath: dbPath.path, contents: nil, attributes: nil)
        }
        db = try! DatabaseQueue(path: dbPath.absoluteString, configuration: config)
        os_log("Initialising application database %@", log: OSLog.default, type: .default, dbPath.absoluteString)
        initDatabase()
        os_log("Application database initializsation is complete", log: OSLog.default, type: .default)
    }
    
    func initDatabase(){
        registerMigrations()
        os_log("Migrations registered", log: OSLog.default, type: .default)
        if let _db = db {
            os_log("About to migrate database", log: OSLog.default, type: .default)
            try! migrator.migrate(_db)
            os_log("Database schema migration complete", log: OSLog.default, type: .default)
        }
    }
}



