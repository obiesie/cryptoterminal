//
//  portfolioTests.swift
//  cryptoterminalTests
//

import Foundation

import GRDB
import XCTest
@testable import cryptoterminal

class PortfolioTests: XCTestCase {
    
    var db:DatabaseQueue?
    
    var portfolio : Portfolio?
    
    override func setUp() {
        super.setUp()
        db = configureDataSource()
        
        if let path = Bundle.main.path(forResource: "insert", ofType: "sql") {
            let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let sql = String(data: data, encoding: .utf8)
            if let _sql = sql{
                do {
                    try db!.inDatabase {
                        db in try db.execute(_sql)
                    }
                } catch {
                    print("Unexpected error: \(error).")
                }
            }
        }
        self.portfolio = Portfolio(db:db!)
    }
    
    func configureDataSource() -> DatabaseQueue {
        let db = DatabaseQueue()
        try! migrator.migrate(db)
        
        var config = Configuration()
        config.foreignKeysEnabled = true
        config.trace = { NSLog($0) }
        
        return db
    }
    
    func testEmptyPortfolio(){
        try! db!.inDatabase {
            db in try db.execute("DELETE FROM BALANCE;")
        }
        if let _portfolio = portfolio{
            XCTAssert(_portfolio.isEmpty)
        }
    }
    
    func testPortfolioPositions(){
        
        try! db!.inDatabase {
            db in try db.execute("""
                    INSERT INTO WALLET VALUES (1,'0xC29BD49928ddd7a9130c27DCC59CA89F2De453Fc','pg',1);
                    INSERT INTO WALLET VALUES (2,'0x525641f43d64B59Ca886FD0F0FE1B7CC253B9aFA','eth1',1);

                    INSERT INTO BALANCE(EXCHANGE, WALLET, CURRENCY, BALANCE) VALUES (NULL,1,31.0,418.504333496094);
                    INSERT INTO BALANCE(EXCHANGE, WALLET, CURRENCY, BALANCE) VALUES (NULL,1,27.0,2835.9921875);
                    INSERT INTO BALANCE(EXCHANGE, WALLET, CURRENCY, BALANCE) VALUES (NULL,2,8.0,20.1573753356934);
                    INSERT INTO BALANCE(EXCHANGE, WALLET, CURRENCY, BALANCE) VALUES (NULL,1,8.0,20.1573753356934);

            """)
        }
        
        if let _portfolio = portfolio {
            let positions = _portfolio.positions
            XCTAssert(positions.count == 3)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
}

