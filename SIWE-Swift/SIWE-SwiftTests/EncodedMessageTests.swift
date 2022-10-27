//
//  EncodedMessageTests.swift
//  SIWE-SwiftTests
//
//  Created by Daniel Bell on 2/21/22.
//

import XCTest
@testable import SIWE_Swift

class EncodedMessageTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSampleMessage() throws {

        let issuedAt = "2021-09-30T16:25:24.000Z"
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        let updatedAtStr = "2016-06-05T16:56:57.019+01:00"
        let updatedAt = dateFormatter.date(from: updatedAtStr)! // "Jun 5, 2016, 4:56 PM"

        let message = SiweMessage(domain: "service.org",
                                  address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
                                uri: "https://service.org/login",
                                version: "1",
                                chainId: 1,
                                statement: "I accept the ServiceOrg Terms of Service: https://service.org/tos",
                                nonce: "32891757",//nil,//"allow internal from 'siwe' generateNonce",
                                issuedAt: updatedAt,
                                resources: ["ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu", "https://example.com/my-web2-claim.json"]
                    )

        let preparedMessage = (try? message.toMessage()) ?? ""
        guard let messageParsed = try? MessageParser(message: preparedMessage) else {
            XCTFail()
            return
        }

        XCTAssertEqual(message.domain, messageParsed.domain)
        XCTAssertEqual(message.address, messageParsed.address)
        XCTAssertEqual(message.statement, messageParsed.statement)
        XCTAssertEqual(message.uri, messageParsed.uri)
        XCTAssertEqual(message.version, messageParsed.version)
        XCTAssertEqual(message.chainId, messageParsed.chainId)
        XCTAssertEqual(message.nonce, messageParsed.nonce)
    }

    func testCustomMessage() throws {

        let issuedAt = "2021-09-30T16:25:24.000Z"
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        let updatedAtStr = "2016-06-05T16:56:57.019+01:00"
        let updatedAt = dateFormatter.date(from: updatedAtStr)! // "Jun 5, 2016, 4:56 PM"

        let message = SiweMessage(domain: "dviances.com",
                                  address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
                                uri: "https://dviances.com/login",
                                version: "1",
                                chainId: 1,
                                requestId: nil,
                                statement: "'Sign in with Ethereum to the app.'",
                                nonce: nil,//"allow internal from 'siwe' generateNonce",
                                issuedAt: nil,
                                expirationTime: nil,
                                notBefore: nil,
                                resources: nil
                    )

        let preparedMessage = (try? message.toMessage()) ?? ""
        guard let messageParsed = try? MessageParser(message: preparedMessage) else {
            XCTFail()
            return
        }

        XCTAssertEqual(message.domain, messageParsed.domain)
        XCTAssertEqual(message.address, messageParsed.address)
        XCTAssertEqual(message.statement, messageParsed.statement)
        XCTAssertEqual(message.uri, messageParsed.uri)
        XCTAssertEqual(message.version, messageParsed.version)
        XCTAssertEqual(message.chainId, messageParsed.chainId)
        XCTAssertNotNil(messageParsed.nonce)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
