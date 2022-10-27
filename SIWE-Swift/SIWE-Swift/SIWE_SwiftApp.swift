//
//  SIWE_SwiftApp.swift
//  SIWE-Swift
//
//  Created by Daniel Bell on 2/5/22.
//

import SwiftUI
import web3swift

//        var signatureString = signature.toHexString()
//
//        if !signatureString.hasPrefix("0x") {
//            signatureString = "0x" + signatureString
//        }
//


@main
struct SIWE_SwiftApp: App {
    @State private var wallet: Wallet? = nil

    var body: some Scene {
        WindowGroup {
            if let ethWallet = wallet {
                Text(ethWallet.address.address)
                    .padding()
                    .background()
                    .onTapGesture {

                        let message = SiweMessage(domain: "dviances.com",
                                                  address: ethWallet.address.address ,
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

                        guard let preparedMessage = try? message.toMessage() else {
                            return
                        }
                        
//                        guard let meessageData = Data.fromHex(preparedMessage) else {return}
                        let meessageData = Data(preparedMessage.utf8)




                        guard let wallet = wallet else {return}

                        let data = wallet.data
                        let keystoreManager: KeystoreManager

                        if wallet.isHD {
                            let keystore = BIP32Keystore(data)!
                            keystoreManager = KeystoreManager([keystore])

                            guard let signature = try? Web3Signer.signPersonalMessage(meessageData, keystore: keystore, account: ethWallet.address, password: "web3swift") else {
    //                            throw Web3Error.dataError
                                return
                            }
                            do {
                                Task {
                                    guard !meessageData.isEmpty, try await message.validate(signature: signature, meessageData: meessageData) else {
                                        //error: 'Expected prepareMessage object as body.'
                                        return
                                    }
                                }
                            } catch {
                                print("error")
                            }

                        } else {
                            let keystore = EthereumKeystoreV3(data)!
                            keystoreManager = KeystoreManager([keystore])

                            guard let signature = try? Web3Signer.signPersonalMessage(meessageData, keystore: keystore, account: ethWallet.address, password: "web3swift") else {
    //                            throw Web3Error.dataError
                                return
                            }
                            do {
                                Task {
                                    guard !meessageData.isEmpty, try await message.validate(signature: signature, meessageData: meessageData) else {
                                        //error: 'Expected prepareMessage object as body.'
                                        return
                                    }
                                }
                            } catch {
                                print("error")
                            }
                        }

                        Task {
                            let web3 = Web3.InfuraMainnetWeb3()
                            web3.addKeystoreManager(keystoreManager)
                        }
                    }
            } else {
                WalletSetupMenuView(wallet: $wallet)
            }

        }
    }
}
import UIKit
import web3swift
class WalletViewController: UIViewController {

    var _walletAddress: String = ""
    var _mnemonics: String = ""


    @IBAction func onClickCreateWallet(_ sender: UIButton) {
        self.createMnemonics()
    }

    fileprivate func createMnemonics(){
        let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let web3KeystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
        do {
            if (web3KeystoreManager?.addresses?.count ?? 0 >= 0) {
                let tempMnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: 256, language: .english)
                guard let tMnemonics = tempMnemonics else {
//                    self.showAlertMessage(title: "", message: "We are unable to create wallet", actionName: "Ok")
                    return
                }
                self._mnemonics = tMnemonics
                print(_mnemonics)
                let tempWalletAddress = try? BIP32Keystore(mnemonics: self._mnemonics , prefixPath: "m/44'/77777'/0'/0")
                print(tempWalletAddress?.addresses?.first?.address as Any)
                guard let walletAddress = tempWalletAddress?.addresses?.first else {
//                    self.showAlertMessage(title: "", message: "We are unable to create wallet", actionName: "Ok")
                    return
                }
                self._walletAddress = walletAddress.address
                let privateKey = try tempWalletAddress?.UNSAFE_getPrivateKeyData(password: "", account: walletAddress)
                let keyData = try? JSONEncoder().encode(tempWalletAddress?.keystoreParams)
                FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keyData, attributes: nil)
            }
        } catch {

        }

    }

}
