//
//  MessageParser.swift
//  SIWE-Swift
//
//  Created by Daniel Bell on 2/16/22.
//

import Foundation

struct MessageParser {

    static let regex = try? NSRegularExpression(pattern: MessageParser.messagePattern, options: [])

    static var messagePattern: String {
        let URI =
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

        let resourcesURI = "(?<resourcesProtocol>([^:]+)s?)?://(?:(?<resourcesUser>[^:\n\r]+):(?<resourcesPass>[^@\n\r]+)@)?(?<resourcesHost>(?:www.)?(?:[^:\\n\r]+))/?(:(?<resourcesPort>[0-9]+))?/?(?<resourcesRequest>[^?\n\r]+)?[?]?([^\n\r]*)"

        let DATETIME = "([0-9]+)-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])[Tt]([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(.[0-9]+)?(([Zz])|([+|-]([01][0-9]|2[0-3]):[0-5][0-9]))"


        let domainPattern = "(?<domain>([^?]*)) wants you to sign in with your Ethereum account:"
        let DOMAIN = "\(domainPattern)"

        let addressPattern = "(?<address>0x[a-zA-Z0-9]{40})"
        let ADDRESS = "\(addressPattern)"

        let STATEMENT = "((?<statement>[^\n]+)\n)?"

        let uriPattern = "\nURI: (?<uri>\(URI)?)"//\n"
        let URI_LINE = "\(uriPattern)"

        let versionPattern = "\nVersion: (?<version>1)"
        let VERSION = "\(versionPattern)"

        let chainIdPattern = "\nChain ID: (?<chainId>[0-9]+)"
        let CHAIN_ID = "\(chainIdPattern)"

        let noncePattern = "\nNonce: (?<nonce>[a-zA-Z0-9]{8,})"
        let NONCE = "\(noncePattern)"

        let issuedAtPattern = "\nIssued At: (?<issuedAt>\(DATETIME))"
        let ISSUED_AT = "\(issuedAtPattern)"

        let expirationTimePattern = "(\nExpiration At: (?<expirationTime>\(DATETIME)))?"
        let EXPIRATION_TIME = "\(expirationTimePattern)"

        let notBeforeTimePattern = "(\nNot Before: (?<notBefore>\(DATETIME)))?"
        let NOT_BEFORE = "\(notBeforeTimePattern)"

        let requestIDPattern = "(\nRequest ID: (?<requestId>[-._~!$&'()*+,;=:@%a-zA-Z0-9]*))?"
        let REQUEST_ID = "\(requestIDPattern)"

        let resourcesNamedpattern = "(?<resources>(\n- \(resourcesURI))+)"
        let resourcesPattern = "(\nResources:\(resourcesNamedpattern))?"//?
        let RESOURCES = "\(resourcesPattern)"

        let messagePattern = "\(DOMAIN)\n\(ADDRESS)\n\n\(STATEMENT)\(URI_LINE)\(VERSION)\(CHAIN_ID)\(NONCE)\(ISSUED_AT)\(EXPIRATION_TIME)\(NOT_BEFORE)\(REQUEST_ID)\(RESOURCES)"

        return messagePattern
    }

    static func value(phrase: String, key: String) throws -> String? {

        let resourcesNsrange = NSRange(phrase.startIndex..<phrase.endIndex, in: phrase)
//        NSRange(location: 0, length: phrase.utf16.count)

        guard let match = regex?.firstMatch(in: phrase, options: [], range: resourcesNsrange) else {
            return nil
        }

        let domainNsrange = match.range(withName: key)

        guard domainNsrange.location != NSNotFound, let domainRange = Range(domainNsrange, in: phrase) else {
            return nil
        }

        return String(phrase[domainRange])
    }

    init(message: String) throws {
        do {

            let resourcesNsrange = NSRange(message.startIndex..<message.endIndex, in: message)
    //        NSRange(location: 0, length: phrase.utf16.count)

            guard let match = MessageParser.regex?.firstMatch(in: message, options: [], range: resourcesNsrange) else {
                return
            }

            let domainNsrange = match.range(withName: "domain")

            guard domainNsrange.location != NSNotFound, let domainRange = Range(domainNsrange, in: message) else {
                return
            }

            let domainFull = String(message[domainRange])


            let domainValue = try MessageParser.value(phrase: message, key: "domain")
            let addressValue = try MessageParser.value(phrase: message, key: "address")
            let statementValue = try MessageParser.value(phrase: message, key: "statement")
            let uriValue = try MessageParser.value(phrase: message, key: "uri")
            let versionValue = try MessageParser.value(phrase: message, key: "version")
            let chainIdValue = try MessageParser.value(phrase: message, key: "chainId")
            let nonceValue = try MessageParser.value(phrase: message, key: "nonce")
            let issuedAtValue = try MessageParser.value(phrase: message, key: "issuedAt")
            let resourcesValue = try MessageParser.value(phrase: message, key: "resources")

            let notBeforeValue = try MessageParser.value(phrase: message, key: "notBefore")
            let requestIdValue = try MessageParser.value(phrase: message, key: "requestId")
            let expirationTimeValue = try MessageParser.value(phrase: message, key: "expirationTime")

            domain = domainValue
            address = addressValue
            statement = statementValue
            uri = uriValue
            version = versionValue
            nonce = nonceValue
            issuedAt = issuedAtValue
            expirationTime = expirationTimeValue
            notBefore = notBeforeValue
            requestId = requestIdValue

            if let chainValue = chainIdValue {
                chainId = Int(chainValue) ?? 1
            }

            let resourceObjects = resourcesValue?
                .split(separator: "\n")
                .map{ substring -> String in

                    let parsedString = String(substring)
                    let prefix = "- "

                    guard parsedString.hasPrefix(prefix) else { return parsedString }
                    return String(parsedString.dropFirst(prefix.count))
                }
            resources = resourceObjects
        } catch {
            print("Unexpected error: \(error).")
            throw error
        }
    }

    var domain: String?
    var address: String?
    var statement: String?
    var uri: String?
    var version: String?
    var nonce: String?
    var issuedAt: String?
    var expirationTime: String?
    var notBefore: String?
    var requestId: String?
    var chainId: Int = 1
    var resources: [String]?
}
