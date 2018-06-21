//
//  DbMigration.swift
//  cryptoterminal
//

import Foundation
import GRDB


var migrator = DatabaseMigrator()

func registerMigrations(){
    
    migrator.registerMigrationWithDeferredForeignKeyCheck("v1.0") { db in
        
        try db.create(table: "CURRENCY_TYPE") { t in
            t.column("ID", .integer)
            t.column("TYPE", .text).unique(onConflict: .ignore)
            t.primaryKey(["ID"])
        }
        
        try db.create(table: "BLOCKCHAIN") { t in
            t.column("ID", .integer)
            t.column("TYPE", .text)
            t.primaryKey(["ID"])
        }
        
        try db.create(table: "EXCHANGE") { t in
            t.column( "ID", .integer)
            t.column( "NAME", .double).defaults(to: 0).notNull().collate(.nocase)
            t.column( "API", .double).defaults(to: 0).notNull().collate(.nocase)
            t.primaryKey(["ID"], onConflict: .replace)
        }
        
        try db.create(table: "CURRENCY") { t in
            t.column("ID", .integer)
            t.column("NAME", .text).notNull().unique(onConflict: .ignore).collate(.nocase)
            t.column("CODE", .integer).notNull().unique(onConflict: .ignore).collate(.nocase)
            t.column("TYPE", .integer).notNull().references("CURRENCY_TYPE", onDelete: .cascade)
            t.column("BALANCE_ENDPOINT", .text)
            t.column("BALANCE_RESPONSE_PATH", .text)
            t.column("BALANCE_DECIMAL_PLACE", .double)
            t.column("IS_EXCHANGE_CURRENCY", .integer).notNull().defaults(to: 0)
            t.column("BLOCKCHAIN", .integer).references("BLOCKCHAIN")
            t.primaryKey(["ID"])
        }
        
        try db.create(table: "CURRENCY_PAIR") { t in
            t.column("ID", .integer)
            t.column("WATCH_LISTED", .text)
            t.column("BASE_CURRENCY", .integer).notNull().references("CURRENCY", onDelete: .cascade)
            t.column("DENOMINATED_CURRENCY", .integer).notNull().references("CURRENCY", onDelete: .cascade)
            t.column("SPOT_RATE", .text)
            t.column("7D_EXCHANGE_DELTA", .integer)
            t.column("1D_EXCHANGE_DELTA", .text)
            t.uniqueKey(["BASE_CURRENCY", "DENOMINATED_CURRENCY"], onConflict: .ignore)
            t.primaryKey(["ID"])
        }
        
        try db.create(table: "WALLET_ADDRESS") { t in
            t.column( "ID", .integer)
            t.column( "ADDRESS", .text)
            t.column( "NAME", .text)
            t.column( "BLOCKCHAIN", .integer).notNull().references("BLOCKCHAIN", onDelete: .cascade)
            t.primaryKey(["ID"])
        }
        
        try db.create(table: "BALANCE") { t in
            t.column("ID", .integer)
            t.column("EXCHANGE", .integer).references("EXCHANGE", onDelete: .cascade)
            t.column( "WALLET_ADDRESS", .integer).references("WALLET_ADDRESS", onDelete: .cascade)
            t.column( "CURRENCY", .double).defaults(to: 0).notNull().references("CURRENCY", onDelete: .cascade)
            t.column( "BALANCE", .double).defaults(to: 0)
            t.primaryKey(["ID"], onConflict: .replace)
        }
        
        try db.create(table: "HISTORICAL_EXCHANGE_RATE") { t in
            t.column("id", .integer).primaryKey()
            t.column("close", .double).notNull()
            t.column("high", .double).notNull()
            t.column("low", .double).notNull()
            t.column("open", .double).notNull()
            t.column("time", .double).notNull()
            t.column("currency_pair", .double).notNull().references("CURRENCY_PAIR", onDelete: .cascade)
            t.uniqueKey(["currency_pair", "time"], onConflict: .replace)
        }
        
      
        try db.create(table: "POSITION") { t in
            t.column( "ID", .text)
            t.column( "CURRENCY", .double).notNull().references("CURRENCY", onDelete: .cascade)
            t.column( "AMOUNT", .double).defaults(to: 0)
            t.column( "COST", .double).defaults(to: 0)
            t.column( "PURCHASE_DATE", .text)
            t.column( "PURCHASE_CURRENCY", .double).references("CURRENCY", onDelete: .cascade)
            t.column( "SIDE", .text)
            t.column( "FIAT_COST", .double)
            t.column( "EXCHANGE", .double).references("EXCHANGE")
            t.primaryKey(["ID"], onConflict: .replace)
        }
        
        if let path = Bundle.main.path(forResource: "insert_v1", ofType: "sql") {
            let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let sql = String(data: data, encoding: .utf8)
            if let _sql = sql{
                try db.execute(_sql)
            }
        }
    }
    
}

