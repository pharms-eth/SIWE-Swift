//
//  SIWE.swift
//  SIWE-Swift
//
//  Created by Daniel Bell on 2/5/22.
//

import Foundation
import web3swift

enum ErrorTypes: String {
    case invalidSignature = "Invalid signature."
    case expiredMessage = "Expired message."
    case malformedSession = "Malformed session."
}

struct SiweMessage {
    var domain: String
    var address: String
    var uri: String
    var version: String
    var chainId: Int
    var requestId: String?
    // Human-readable assertion that the user will sign, must not contain `\n`.
    var statement: String?
    // Randomized token, at least 8 alphanumeric characters.
    var nonce: String?
    // ISO 8601 datetime string
    var issuedAt: Date?
    // ISO 8601 datetime string that, if present, indicates when the signed authentication message is no longer valid
    var expirationTime: String?
    // ISO 8601 datetime string that, if present, indicates when the signed authentication message will become valid
    var notBefore: String?
    // They are expressed as RFC 3986 URIs separated by `\n- `
    var resources: [String]?


//    constructor(param: string | Partial<SiweMessage>) {
//        if (typeof param === 'string') {
//            const parsedMessage = new ABNFParsedMessage(param);
//            this.domain = parsedMessage.domain;
//            this.address = parsedMessage.address;
//            this.statement = parsedMessage.statement;
//            this.uri = parsedMessage.uri;
//            this.version = parsedMessage.version;
//            this.nonce = parsedMessage.nonce;
//            this.issuedAt = parsedMessage.issuedAt;
//            this.expirationTime = parsedMessage.expirationTime;
//            this.notBefore = parsedMessage.notBefore;
//            this.requestId = parsedMessage.requestId;
//            this.chainId = parsedMessage.chainId;
//            this.resources = parsedMessage.resources;
//        }
//    }

    enum MessageError: Error {
        case nonceFailed
    }

    /**
     * This function can be used to retrieve an EIP-4361 formated message for
     * signature
     * @returns {string} EIP-4361 formated message, ready for EIP-191 signing.
     */
    func toMessage() throws -> String {
        let header = "\(domain) wants you to sign in with your Ethereum account:"
        let uriField = "URI: \(uri)"
        var prefix = header + "\n" + address
        let versionField = "Version: \(version)"
        guard let instanceNonce = nonce ?? generateNonce() else {
            throw MessageError.nonceFailed
        }

        let chainField = "Chain ID: \(chainId)"
        let nonceField = "Nonce: " + instanceNonce

        var suffixArray = [uriField, versionField, chainField, nonceField]

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.calendar = Calendar(identifier: .gregorian)

        let iso8601String = dateFormatter.string(from: issuedAt ?? Date())

        suffixArray.append("Issued At: \(iso8601String)")

        if let time = expirationTime {
            suffixArray.append("Expiration Time: \(time)")
        }

        if let value = notBefore {
            suffixArray.append("Not Before: \(value)")
        }

        if let value = requestId {
            suffixArray.append("Request ID: \(value)")
        }

        if let values = resources {
            let formatted = values.map { "- " + $0 }.joined(separator: "\n")
            suffixArray.append(["Resources:", formatted].joined(separator: "\n"))
        }

        let suffix = suffixArray.joined(separator: "\n")

        if let statement = statement {
            prefix = [prefix, statement].joined(separator: "\n\n")
            prefix += "\n"
        }

        return [prefix, suffix].joined(separator: "\n");
    }

    func generateNonce() -> String? {
        var bytes = [UInt8](repeating: 0, count: 256)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard result == errSecSuccess else {
            print("Problem generating random bytes")
            return nil
        }

        let rawString = Data(bytes).base64EncodedString()
        let pattern = "[^A-Za-z0-9]+"
        let newString = rawString.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        return newString
    }

    /**
     * Validates the integrity of the fields of this objects by matching it's
     * signature.
     * @param provider A Web3 provider able to perform a contract check, this is
     * required if support for Smart Contract Wallets that implement EIP-1271 is
     * needed.
     * @returns {Promise<SiweMessage>} This object if valid.
     */

    enum ValidationErrors: Error {
        case malformedSession([String])
        case invalidSignature(String, String)
        case expiredMessage
    }

    //    var signature: string?
    func validate(signature: Data, meessageData: Data) async throws -> Bool {
        let web3 = Web3.InfuraMainnetWeb3()

        let addr = try web3.personal.ecrecover(personalMessage: meessageData, signature: signature)

        if addr.address != self.address {



//============================================================================
            let to = EthereumAddress("0x3F06bAAdA68bB997daB03d91DBD0B73e196c5A4d")!
            let value = EIP712.UInt256(0)
            let amount = EIP712.UInt256("0001000000000000000")

            let function = ABI.Element.Function(
                name: "approveAndMint",
                inputs: [
                    .init(name: "cToken", type: .address),
                    .init(name: "mintAmount", type: .uint(bits: 256))],
                outputs: [.init(name: "", type: .bool)],
                constant: false,
                payable: false)

            let object = ABI.Element.function(function)

            let safeTxData = object.encodeParameters([
                EthereumAddress("0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72")! as AnyObject,
                amount as AnyObject
            ])!

            let operation: EIP712.UInt8 = 1
            let safeTxGas = EIP712.UInt256(250000)
            let baseGas = EIP712.UInt256(60000)
            let gasPrice = EIP712.UInt256("20000000000")
            let gasToken = EthereumAddress("0x0000000000000000000000000000000000000000")!
            let refundReceiver = EthereumAddress("0x7c07D32e18D6495eFDC487A32F8D20daFBa53A5e")!
            let nonce: EIP712.UInt256 = .init(0)

            let safeTX = SafeTx(
                to: to,
                value: value,
                data: safeTxData,
                operation: operation,
                safeTxGas: safeTxGas,
                baseGas: baseGas,
                gasPrice: gasPrice,
                gasToken: gasToken,
                refundReceiver: refundReceiver,
                nonce: nonce)

            let mnemonic = "normal dune pole key case cradle unfold require tornado mercy hospital buyer"
            let keystore = try! BIP32Keystore(mnemonics: mnemonic, password: "", mnemonicsPassword: "")!

            let verifyingContract = EthereumAddress("0x76106814dc6150b0fe510fbda4d2d877ac221270")!
            let account = keystore.addresses?[0]
            let password  = ""
            let chainId: EIP712.UInt256? = EIP712.UInt256(42)

            let signature = try Web3Signer.signEIP712(
                safeTx: safeTX,
                keystore: keystore,
                verifyingContract: verifyingContract,
                account: account!,
                password: password,
                chainId: chainId)
//=============================================================================================
//            let toEthereumAddress: EthereumAddress = EthereumAddress(address)
//
//            let yourContractABI = ABI.Element.Function(
//                name: "isValidSignature",
//                inputs: [
//                    .init(name: "_message", type: .bytes(length: 32)),
//                    .init(name: "_signature", type: .bytes(length: 256))],
//                outputs: [.init(name: "", type: .bool)],
//                constant: false,
//                payable: false)
//
//            let object = ABI.Element.function(function)
//
//            let safeTxData = object.encodeParameters([
//                toEthereumAddress! as AnyObject,
//                amount as AnyObject
//            ])!
//
//            let operation: EIP712.UInt8 = 1
//            let safeTxGas = EIP712.UInt256(250000)
//            let baseGas = EIP712.UInt256(60000)
//            let gasPrice = EIP712.UInt256("20000000000")
//            let gasToken = EthereumAddress("0x0000000000000000000000000000000000000000")!
//            let refundReceiver = EthereumAddress("0x7c07D32e18D6495eFDC487A32F8D20daFBa53A5e")!
//            let nonce: EIP712.UInt256 = .init(0)


            //            let : String = "function (bytes32 , bytes ) public view returns (bool)"
//            let hashMessage = Web3Utils.hashPersonalMessage(meessageData)
            //            let contract = web3.contract(yourContractABI, at: toEthereumAddress)
            //            let transaction = contract?.read("isValidSignature", parameters: [signature as NSData, hashMessage as NSData])







//            //EIP-1271
//            let yourContractABI: String = "function isValidSignature(bytes32 _message, bytes _signature) public view returns (bool)"
//            guard let toEthereumAddress: EthereumAddress = EthereumAddress(address), let hashMessage = Web3Utils.hashPersonalMessage(meessageData) else {
//                throw ValidationErrors.invalidSignature(addr.address, self.address)
//            }
//    //TODO: debug, does not work
//            let contract = web3.contract(yourContractABI, at: toEthereumAddress)
//
//            let transaction = contract?.read("isValidSignature", parameters: [signature as NSData, hashMessage as NSData])
//            print("hello")
            
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.calendar = Calendar(identifier: .gregorian)


        if let time = notBefore {
            guard let exp = dateFormatter.date(from: time) else {
                throw ValidationErrors.malformedSession(["invalid expiration date"])
            }
            
            if Date() >= exp {
                throw ValidationErrors.expiredMessage
            }
        }
        if let time = expirationTime {
            guard let exp = dateFormatter.date(from: time) else {
                throw ValidationErrors.malformedSession(["invalid expiration date"])
            }

            if Date() >= exp {
                throw ValidationErrors.expiredMessage
            }
        }

        return true
    }

}

