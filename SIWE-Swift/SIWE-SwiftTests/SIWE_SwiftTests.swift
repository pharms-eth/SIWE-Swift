//
//  SIWE_SwiftTests.swift
//  SIWE-SwiftTests
//
//  Created by Daniel Bell on 2/5/22.
//

import Foundation

import XCTest
@testable import SIWE_Swift

class SIWEParsingTests: XCTestCase {

    var positiveTestData: ParsingPositive?

    override func setUp() {
        let positivedata = Bundle.main.open("parsing_positive")
        positiveTestData = try? JSONDecoder().decode(ParsingPositive.self, from: positivedata)
    }

    func testURIExpression() throws {

        let phrase =
//        "https://service.org/tos"
//          "https://bartjacobs:mypassword@service.org/login"
//                "ipfs://bartjacobs:mypassword@Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu"
//          "https://bartjacobs:mypassword@example.com/my-web2-claim.json"
//                  "ipfs://bartjacobs:mypassword@Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu"
//          "https://bartjacobs:mypassword@example.com/my-web2-claim.json"
//          "ftp://bartjacobs:mypassword@ftp.is.co.za/rfc/rfc1808.txt"
//          "http://bartjacobs:mypassword@www.ietf.org/rfc/rfc2396.txt"
//                "telnet://bartjacobs:mypassword@192.0.2.16:80/"
//          "https://bartjacobs:mypassword@service.org/login?token=123456&query=swift%20ios"
          "telnet://bartjacobs:mypassword@192.0.2.16:80/?token=123456&query=swift%20ios"
//            "https://service.org/tos"
//            "https://service.org/login"
//            "ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu"
//            "https://example.com/my-web2-claim.json"
//            "ftp://ftp.is.co.za/rfc/rfc1808.txt"
//            "http://www.ietf.org/rfc/rfc2396.txt"
//            "ldap://[2001:db8::7]/c=GB?objectClass?one"
//            "telnet://192.0.2.16:80/"

        let pattern =
        #"""
        (?xi)
        (?<protocol>(?:[^:]+)s?)?:\/\/
        (?:(?<user>[^:\n\r]+):(?<pass>[^@\n\r]+)@)?
        (?<host>(?:www\.)?(?:[^:\/\n\r]+))/?
        (?::(?<port>\d+))?\/?
        (?<request>[^?\n\r]+)
        ?\??
        (?<query>[^\n\r]*)
        """#

        let addressRegex = try NSRegularExpression(pattern: pattern, options: [])
        let addressNsrange = NSRange(phrase.startIndex..<phrase.endIndex, in: phrase)
//        NSRange(location: 0, length: phrase.utf16.count)
        let component = "query"

        guard let match = addressRegex.firstMatch(in: phrase, options: [], range: addressNsrange) else {
            XCTFail("\(component) not found")
            return
        }

        let nsrange = match.range(withName: component)

        guard nsrange.location != NSNotFound, let range = Range(nsrange, in: phrase) else {
            XCTFail("\(component) not found in range: \(nsrange)")
            return
        }

        XCTAssertEqual(component, "query")
        XCTAssertEqual(phrase[range], "token=123456&query=swift%20ios")
    }

    func testURIParsing() throws {
        let phrase =
            "service.org wants you to sign in with your Ethereum account:\n345\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\naddress: 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\n 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z"


        //  "service.org wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z")

        // "service.org wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z\nResources:\n- ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu\n- https://example.com/my-web2-claim.json")

        let URIMulti =
        #"""
        (?xi)
        (?<protocol>(?:[^:]+)s?)?:\/\/
        (?:(?<user>[^:\n\r]+):(?<pass>[^@\n\r]+)@)?
        (?<host>(?:www\.)?(?:[^:\/\n\r]+))/?
        (?::(?<port>\d+))?\/?
        (?<request>[^?\n\r]+)
        ?\??
        (?<query>[^\n\r]*)
        """#

        let pattern = "\nURI: (?<uri>\(URIMulti)?)"

        let regex = try NSRegularExpression(pattern: pattern, options: [])

        let uriNsrange = NSRange(phrase.startIndex..<phrase.endIndex, in: phrase)
//        NSRange(location: 0, length: phrase.utf16.count)
        let component = "uri"

        guard let match = regex.firstMatch(in: phrase, options: [], range: uriNsrange) else {
            XCTFail("\(component) not found")
            return
        }

        let nsrange = match.range(withName: component)

        guard nsrange.location != NSNotFound, let range = Range(nsrange, in: phrase) else {
            XCTFail("\(component) not found in range: \(nsrange)")
            return
        }

        XCTAssertEqual(component, "uri")
        XCTAssertEqual(phrase[range], "https://service.org/login")
    }

    func testResourcesParsing() throws {
        let phrase =
        "service.org wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z\nResources:\n- ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu\n- https://example.com/my-web2-claim.json)"

        let URI = "(?<resourcesProtocol>([^:]+)s?)?://(?:(?<resourcesUser>[^:\n\r]+):(?<resourcesPass>[^@\n\r]+)@)?(?<resourcesHost>(?:www.)?(?:[^:\\n\r]+))/?(:(?<resourcesPort>[0-9]+))?/?(?<resourcesRequest>[^?\n\r]+)?[?]?([^\n\r]*)"

        let resourcesNamedpattern = "(?<resources>(\n- \(URI))+)"
        let pattern = "(\nResources:\(resourcesNamedpattern))"

        let patternExpanded = "(?<domain>([^?]*)) wants you to sign in with your Ethereum account:\n(?<address>0x[a-zA-Z0-9]{40})\n\n((?<statement>[^\n]+)\n)\nURI: (?<uri>(?xi)\n(?<protocol>(?:[^:]+)s?)?:\\/\\/\n(?:(?<user>[^:\\n\\r]+):(?<pass>[^@\\n\\r]+)@)?\n(?<host>(?:www\\.)?(?:[^:\\/\\n\\r]+))/?\n(?::(?<port>\\d+))?\\/?\n(?<request>[^?\\n\\r]+)\n?\\??\n(?<query>[^\\n\\r]*)?)\nVersion: (?<version>1)\nChain ID: (?<chainId>[0-9]+)\nNonce: (?<nonce>[a-zA-Z0-9]{8,})\nIssued At: (?<issuedAt>([0-9]+)-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(.[0-9]+)?(([Zz])|([+|-]([01][0-9]|2[0-3]):[0-5][0-9])))(\nExpiration At: (?<expirationTime>([0-9]+)-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(.[0-9]+)?(([Zz])|([+|-]([01][0-9]|2[0-3]):[0-5][0-9]))))?(\nNot Before: (?<notBefore>([0-9]+)-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(.[0-9]+)?(([Zz])|([+|-]([01][0-9]|2[0-3]):[0-5][0-9]))))?(\nRequest ID: (?<requestId>[-._~!$&\'()*+,;=:@%a-zA-Z0-9]*))?(\nResources:(?<resources>(\n- \(URI))+))"

        do {
            let regex = try NSRegularExpression(pattern: patternExpanded, options: [])
            let resourcesNsrange = NSRange(phrase.startIndex..<phrase.endIndex, in: phrase)
    //        NSRange(location: 0, length: phrase.utf16.count)

            let component = "resources"

            guard let match = regex.firstMatch(in: phrase, options: [], range: resourcesNsrange) else {
                XCTFail("\(component) not found")
                return
            }

            let nsrange = match.range(withName: component)

            guard nsrange.location != NSNotFound, let range = Range(nsrange, in: phrase) else {
                XCTFail("\(component) not found in range: \(nsrange)")
                return
            }

            XCTAssertEqual(phrase[range],
            """

            - ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu
            - https://example.com/my-web2-claim.json)
            """)
        } catch let error {
            print(error)
            XCTFail()
        }

    }

    func testIssuedParsing() throws {
        let phrase =
            "service.org wants you to sign in with your Ethereum account:\n345\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\naddress: 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\n 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z"


        //  "service.org wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z")

        // "service.org wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z\nResources:\n- ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu\n- https://example.com/my-web2-claim.json")

        let DATETIME = "([0-9]+)-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(.[0-9]+)?(([Zz])|([+|-]([01][0-9]|2[0-3]):[0-5][0-9]))"


        let pattern = "\nIssued At: (?<issuedAt>\(DATETIME))"


        let regex = try NSRegularExpression(pattern: pattern, options: [])

        let issuedAtNsrange = NSRange(phrase.startIndex..<phrase.endIndex, in: phrase)
//        NSRange(location: 0, length: phrase.utf16.count)

        let component = "issuedAt"

        guard let match = regex.firstMatch(in: phrase, options: [], range: issuedAtNsrange) else {
            XCTFail("\(component) not found")
            return
        }

        let nsrange = match.range(withName: component)

        guard nsrange.location != NSNotFound, let range = Range(nsrange, in: phrase) else {
            XCTFail("\(component) not found in range: \(nsrange)")
            return
        }

        XCTAssertEqual(component, "issuedAt")
        XCTAssertEqual(phrase[range], "2021-09-30T16:25:24.000Z")
    }

    func testMessageParsing() throws {
        let phrase =
      "service.org wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z\nResources:\n- ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu\n- https://example.com/my-web2-claim.json"

        do {
            let message = try MessageParser(message: phrase)
            XCTAssertEqual(message.domain, "service.org")
            XCTAssertEqual(message.address, "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")
            XCTAssertEqual(message.statement, "I accept the ServiceOrg Terms of Service: https://service.org/tos")
            XCTAssertEqual(message.uri, "https://service.org/login")
            XCTAssertEqual(message.version, "1")
            XCTAssertEqual(message.chainId, 1)
            XCTAssertEqual(message.nonce, "32891757")
            XCTAssertEqual(message.issuedAt, "2021-09-30T16:25:24.000Z")
            XCTAssertEqual(message.resources,
               [
                "ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu",
                "https://example.com/my-web2-claim.json"
               ]
            )

        } catch let error {
            print(error)
            XCTFail()
        }
    }

    func testCoupleOfOptionalFields() throws {
        guard let abc = positiveTestData?.coupleOfOptionalFields else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.statement, messageParsed.statement)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)
        XCTAssertEqual(messageValid.resources, messageParsed.resources)

    }

    //8 more tests
    func testNoStatement() throws {
        guard let abc = positiveTestData?.noStatement else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)

    }
//    "domain is RFC 3986 authority with userinfo and port"
    func testAuthorityWithUserinfoAndPort() throws {
        guard let abc = positiveTestData?.domainIsRFC3986AuthorityWithUserinfoAndPort else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.statement, messageParsed.statement)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)
    }
//    "domain is RFC 3986 authority with port"
    func testAuthorityWithPort() throws {
        guard let abc = positiveTestData?.domainIsRFC3986AuthorityWithPort else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.statement, messageParsed.statement)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)
        XCTAssertEqual(messageValid.resources, messageParsed.resources)

    }
//    "domain is RFC 3986 authority with userinfo"
    func testAuthorityWithUserinfo() throws {
        guard let abc = positiveTestData?.domainIsRFC3986AuthorityWithUserinfo else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.statement, messageParsed.statement)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)
        XCTAssertEqual(messageValid.resources, messageParsed.resources)

    }
//    "domain is RFC 3986 authority with IP"
    func testAuthorityWithIP() throws {
        guard let abc = positiveTestData?.domainIsRFC3986AuthorityWithIP else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.statement, messageParsed.statement)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)
        XCTAssertEqual(messageValid.resources, messageParsed.resources)

    }
//    "timestamp without microseconds"
    func testTimestampWithoutMicroseconds() throws {
        guard let abc = positiveTestData?.timestampWithoutMicroseconds else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.statement, messageParsed.statement)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)
        XCTAssertEqual(messageValid.resources, messageParsed.resources)

    }
//    "no optional field"
    func testNoOptionalFields() throws {
        guard let abc = positiveTestData?.noOptionalField else {
            XCTFail()
            return
        }

        let messageRaw = abc.message

        let messageParsed = try MessageParser(message: messageRaw)

        let messageValid = abc.fields

        XCTAssertEqual(messageValid.domain, messageParsed.domain)
        XCTAssertEqual(messageValid.address, messageParsed.address)
        XCTAssertEqual(messageValid.statement, messageParsed.statement)
        XCTAssertEqual(messageValid.uri, messageParsed.uri)
        XCTAssertEqual(messageValid.version, messageParsed.version)
        XCTAssertEqual(messageValid.chainID, messageParsed.chainId)
        XCTAssertEqual(messageValid.nonce, messageParsed.nonce)
        XCTAssertEqual(messageValid.issuedAt, messageParsed.issuedAt)
    }
}

extension Bundle {
    func open(_ file: String) -> Data {
        guard let url = self.url(forResource: file, withExtension: "json") else {
            fatalError("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }

        return data
    }
}
struct ParsingPositive: Codable {
    let coupleOfOptionalFields, noOptionalField, timestampWithoutMicroseconds, domainIsRFC3986AuthorityWithIP: CoupleOfOptionalFields
    let domainIsRFC3986AuthorityWithUserinfo, domainIsRFC3986AuthorityWithPort, domainIsRFC3986AuthorityWithUserinfoAndPort, noStatement: CoupleOfOptionalFields

    enum CodingKeys: String, CodingKey {
        case coupleOfOptionalFields = "couple of optional fields"
        case noOptionalField = "no optional field"
        case timestampWithoutMicroseconds = "timestamp without microseconds"
        case domainIsRFC3986AuthorityWithIP = "domain is RFC 3986 authority with IP"
        case domainIsRFC3986AuthorityWithUserinfo = "domain is RFC 3986 authority with userinfo"
        case domainIsRFC3986AuthorityWithPort = "domain is RFC 3986 authority with port"
        case domainIsRFC3986AuthorityWithUserinfoAndPort = "domain is RFC 3986 authority with userinfo and port"
        case noStatement = "no statement"
    }
}

// MARK: - CoupleOfOptionalFields
struct CoupleOfOptionalFields: Codable {
    let message: String
    let fields: Fields

    struct Fields: Codable {
        let domain, address: String
        let statement: String?
        let uri: String
        let version: String
        let chainID: Int
        let nonce, issuedAt: String
        let resources: [String]?

        enum CodingKeys: String, CodingKey {
            case domain, address, statement, uri, version
            case chainID = "chainId"
            case nonce, issuedAt, resources
        }
    }
}

// MARK: - Fields



//"timestamp without microseconds": {
//    "message": "service.org wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24Z",
//    "fields": {
//        "domain": "service.org",
//        "address": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
//        "statement": "I accept the ServiceOrg Terms of Service: https://service.org/tos",
//        "uri": "https://service.org/login",
//        "version": "1",
//        "chainId": 1,
//        "nonce": "32891757",
//        "issuedAt": "2021-09-30T16:25:24Z"
//    }
//},
//"domain is RFC 3986 authority with IP": {
//    "message": "127.0.0.1 wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z",
//    "fields": {
//        "domain": "127.0.0.1",
//        "address": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
//        "statement": "I accept the ServiceOrg Terms of Service: https://service.org/tos",
//        "uri": "https://service.org/login",
//        "version": "1",
//        "chainId": 1,
//        "nonce": "32891757",
//        "issuedAt": "2021-09-30T16:25:24.000Z"
//    }
//},
//"domain is RFC 3986 authority with userinfo": {
//    "message": "test@127.0.0.1 wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z",
//    "fields": {
//        "domain": "test@127.0.0.1",
//        "address": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
//        "statement": "I accept the ServiceOrg Terms of Service: https://service.org/tos",
//        "uri": "https://service.org/login",
//        "version": "1",
//        "chainId": 1,
//        "nonce": "32891757",
//        "issuedAt": "2021-09-30T16:25:24.000Z"
//    }
//},
//"domain is RFC 3986 authority with port": {
//    "message": "127.0.0.1:8080 wants you to sign in with your Ethereum account:\n0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2\n\nI accept the ServiceOrg Terms of Service: https://service.org/tos\n\nURI: https://service.org/login\nVersion: 1\nChain ID: 1\nNonce: 32891757\nIssued At: 2021-09-30T16:25:24.000Z",
//    "fields": {
//        "domain": "127.0.0.1:8080",
//        "address": "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
//        "statement": "I accept the ServiceOrg Terms of Service: https://service.org/tos",
//        "uri": "https://service.org/login",
//        "version": "1",
//        "chainId": 1,
//        "nonce": "32891757",
//        "issuedAt": "2021-09-30T16:25:24.000Z"
//    }
//},

