//
//  cryptoterminalTests.swift
//  cryptoterminalTests
//
//  Created by Obiesie Ike-Nwosu on 6/22/17.
//  Copyright © 2017 Obiesie Ike-Nwosu. All rights reserved.
//

import XCTest
@testable import cryptoterminal

class cryptoterminalTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParsingGdaxData() {
        let gdaxData : [[String:Any]] = [
            ["product_id": "ETH-BTC", "liquidity": "M", "profile_id": "e21eb74e-8a2e-4e18-896b-297c6cfe016b", "order_id": "6c473682-89ec-4441-bf65-920a029a48ae", "side": "buy", "created_at": "2017-10-09T14:38:49.677Z", "settled": "1", "size": "2.00000000", "user_id": "55bff2ad64d5193a460000d8", "fee": "0.0000000000000000", "price": "0.06500000", "trade_id": "1595558"],
            ["product_id": "BTC-GBP", "liquidity": "M", "profile_id": "e21eb74e-8a2e-4e18-896b-297c6cfe016b", "order_id": "5255ca6a-78b0-45c4-a7fb-c008d442d85d", "side": "sell", "created_at": "2017-11-01T22:49:01.675Z", "settled": "1", "size": "0.02481072", "user_id": "55bff2ad64d5193a460000d8", "fee": "0.0000000000000000", "price": "5090.00000000", "trade_id": "1466948"],
            ["product_id": "BTC-GBP", "liquidity": "M", "profile_id": "e21eb74e-8a2e-4e18-896b-297c6cfe016b", "order_id": "5255ca6a-78b0-45c4-a7fb-c008d442d85d", "side": "sell", "created_at": "2017-11-01T22:48:57.896Z", "settled": "1", "size": "0.18000000", "user_id": "55bff2ad64d5193a460000d8", "fee": "0.0000000000000000", "price": "5090.00000000", "trade_id": "1466947"]
        ]
        var orderIds : Set<String> = []
        gdaxData.forEach{ element in
            orderIds.insert(element["order_id"] as! String)
        }
        let positions = Position.positionFrom(exchange: .GDAX, transactionData: gdaxData)
        XCTAssertEqual(positions.count, orderIds.count)
        for position in positions{
            if position.baseCurrency.code == "BTC" {
                XCTAssertEqual( position.quantity, 0.18000000 + 0.02481072)
            }
        }
    }
    
    func testParsingOrderDataFromFile(){
        guard let pathString = Bundle(for: type(of: self)).path(forResource: "testTrades", ofType: "csv") else {
            fatalError("Test csv import file not found")
        }
        let importStatus = Position.positionFromFile(filePath: pathString);
        XCTAssertEqual(importStatus.count, 9)
        XCTAssertEqual(importStatus.compactMap{$0}.count, 8)
    }
}
