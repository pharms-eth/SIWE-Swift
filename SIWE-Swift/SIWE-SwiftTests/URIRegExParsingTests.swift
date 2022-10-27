//
//  URIRegExParsingTests.swift
//  SIWE-SwiftTests
//
//  Created by Daniel Bell on 2/12/22.
//

import XCTest

class URIRegExParsingTests: XCTestCase {
    //        (?<protocol>(?:[^:]+)s?)?:\/\/

//            #"""
//            (?xi)
//            (?<protocol>(?:[^:]+)s?)?:\/\/
//            (?:(?<user>[^:\n\r]+):(?<pass>[^@\n\r]+)@)?
//            """#

    func testProtocol() throws {
        let phrase = //"https://service.org/tos"
            "https://service.org/login"
//            "ipfs://Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu"
//            "https://example.com/my-web2-claim.json"
//            "ftp://ftp.is.co.za/rfc/rfc1808.txt"
//            "http://www.ietf.org/rfc/rfc2396.txt"
//            "ldap://[2001:db8::7]/c=GB?objectClass?one"
//                    "mailto:John.Doe@example.com"
//                    "news:comp.infosystems.www.servers.unix"
//                    "tel:+1-816-555-1212"
//            "telnet://192.0.2.16:80/"
//                    "urn:oasis:names:specification:docbook:dtd:xml:4.1.2"

        let pattern =
        #"""
        (?xi)
        (?<protocol>(?:[^:]+)s?)?:\/\/
        """#

        let addressRegex = try NSRegularExpression(pattern: pattern, options: [])

        let addressNsrange = NSRange(phrase.startIndex..<phrase.endIndex, in: phrase)
//        NSRange(location: 0, length: phrase.utf16.count)
        let component = "protocol"

        guard let match = addressRegex.firstMatch(in: phrase, options: [], range: addressNsrange) else {
            XCTFail("\(component) not found")
            return
        }

        let nsrange = match.range(withName: component)

        guard nsrange.location != NSNotFound, let range = Range(nsrange, in: phrase) else {
            XCTFail("\(component) not found in range: \(nsrange)")
            return
        }

        XCTAssertEqual(component, "protocol")
        XCTAssertEqual(phrase[range], "https")
    }

    func testUser() throws {

        let phrase = //"https://service.org/tos"
//          "https://bartjacobs:mypassword@service.org/login"
//          "ipfs://bartjacobs:mypassword@Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu"
//          "https://bartjacobs:mypassword@example.com/my-web2-claim.json"
//
//          "ipfs://bartjacobs:mypassword@Qme7ss3ARVgxv6rXqVPiikMJ8u2NLgmgszg13pYrDKEoiu"
//          "https://bartjacobs:mypassword@example.com/my-web2-claim.json"
//          "ftp://bartjacobs:mypassword@ftp.is.co.za/rfc/rfc1808.txt"
//          "http://bartjacobs:mypassword@www.ietf.org/rfc/rfc2396.txt"
//          "ldap://bartjacobs:mypassword@[2001:db8::7]/c=GB?objectClass?one"
          "https://bartjacobs:mypassword@myapi.com?token=123456&query=swift%20ios#five"
//                                "mailto:bartjacobs:mypassword@John.Doe@example.com"
//                                "news:bartjacobs:mypassword@comp.infosystems.www.servers.unix"
//                                "tel:bartjacobs:mypassword@+1-816-555-1212"
//          "telnet://bartjacobs:mypassword@192.0.2.16:80/"
//                                "urn:oasis:names:specification:docbook:dtd:xml:4.1.2"


        let pattern =
        #"""
        (?xi)
        (?<protocol>(?:[^:]+)s?)?:\/\/
        (?:(?<user>[^:\n\r]+):(?<pass>[^@\n\r]+)@)?
        """#

        let addressRegex = try NSRegularExpression(pattern: pattern, options: [])

        let addressNsrange = NSRange(phrase.startIndex..<phrase.endIndex, in: phrase)
//        NSRange(location: 0, length: phrase.utf16.count)
        let component = "user"

        guard let match = addressRegex.firstMatch(in: phrase, options: [], range: addressNsrange) else {
            XCTFail("\(component) not found")
            return
        }

        let nsrange = match.range(withName: component)

        guard nsrange.location != NSNotFound, let range = Range(nsrange, in: phrase) else {
            XCTFail("\(component) not found in range: \(nsrange)")
            return
        }

        XCTAssertEqual(component, "user")
        XCTAssertEqual(phrase[range], "bartjacobs")
    }
}
