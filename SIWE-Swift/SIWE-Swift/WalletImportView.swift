//
//  WalletImportView.swift
//  SIWE-Swift
//
//  Created by Daniel Bell on 2/18/22.
//

import SwiftUI
import web3swift

struct Wallet {
    let address: EthereumAddress
    let data: Data
    let name: String
    let isHD: Bool
}

class WalletImportViewModel: ObservableObject {
    @Published var error: String?
    @Published var editText: String = ""
    @Published var password1Text: String = ""
    @Published var password2Text: String = ""
    @Published var faceIsOn = false

    func importWallet() async -> Wallet? {
        var password: String? = nil

        editText = ""//"5be307eed5a14f93eccb720abb9febaeeefcae43609566920ac573864fe294e0"
        //        editText = "goddess cook glass fossil shrug tree rule raccoon useless phone valley frown"

        if !password1Text.isEmpty && !password2Text.isEmpty {
            if password1Text != password1Text {
                error = "It looks like you attempted to create a password, please complete"
                return nil
            } else {
                password = password1Text
            }
        } else if !password1Text.isEmpty || !password2Text.isEmpty {
            error = "It looks like you attempted to create a password, please complete or clear"
            return nil
        }

        let wordList = editText.components(separatedBy: " ")

        if wordList.count >= 12 && wordList.count.isMultiple(of: 3) && wordList.count <= 24 {
            return importWalletWithMnemonics(password: password ?? "web3swift")
        } else if editText.count == 32 {
            return importWalletWithPrivateKey(password: password ?? "web3swift")
        } else {
//            let web3 = Web3.InfuraMainnetWeb3()
//            let ens = ENS(web3: web3)!
//
//            do {
//                //TODO: remove promise kit
//                //TODO: remove starscream
//                let domain = "pharms.eth"
//                let resolver = try await ens.registry.getResolver(forDomain: domain)
//                let pubkey = try await resolver.getPublicKey(forNode: domain)
//                let address = try await resolver.getAddress(forNode: domain)
//                let ttl = try await ens.registry.getTTL(node: domain)
//                let owner = try await ens.registry.getOwner(node: domain)
//
//                print(pubkey.x)
//                print(pubkey.y)
//            } catch {
//                print("crashed")
//            }


            return nil
        }
    }

    func importWalletWithPrivateKey(password: String = "web3swift") -> Wallet? {

        let privateKey = editText

        let formattedKey = privateKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let dataKey = Data.fromHex(formattedKey) else {
            self.error = "Please enter a valid Private key"
            return nil
        }

        do {
            guard let keystore =  try EthereumKeystoreV3(privateKey: dataKey, password: password) else {
                self.error = "Please enter correct Private key"
                return nil
            }

            guard let keyData = try? JSONEncoder().encode(keystore.keystoreParams), let address = keystore.addresses?.first else {
                return nil
            }

            let wallet = Wallet(address: address, data: keyData, name: "New Wallet", isHD: false)
            return wallet
        } catch {
            self.error = "Please enter correct Private key"
        }

        return nil
    }

    func importWalletWithMnemonics(password: String = "web3swift") -> Wallet? {
        let mnemonics = editText

        guard
            let bip32keystore = try? BIP32Keystore(mnemonics: mnemonics, password: password, prefixPath: "m/44'/77777'/0'/0"),
            let bip32keyData = try? JSONEncoder().encode(bip32keystore.keystoreParams),
            let bip32address = bip32keystore.addresses?.first
        else {
            return nil
        }

        let wallet = Wallet(address: bip32address, data: bip32keyData, name: "New Wallet", isHD: true)
        return wallet
    }
}

struct WalletImportView: View {
    @Binding public var ethWallet: Wallet?
    @Binding public var showView: Bool
    @StateObject private var viewModel = WalletImportViewModel()


    init(wallet: Binding<Wallet?>, showView show: Binding<Bool>) {
        UITextView.appearance().backgroundColor = .clear // First, remove the UITextView's backgroundColor.
        _ethWallet = wallet
        _showView = show
    }

    var body: some View {
        VStack(alignment: .center) {
            Text("Import Account")
                .padding(10)
                .foregroundColor(Color.labelForeground)
                .font(.system(size: 24.0, weight: .heavy))

            Spacer()

            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Seed Phase")
                        .foregroundColor(Color.labelForeground)
                        .font(.system(size: 12, weight: .light))
                        .padding(.bottom, 2)
                    TextEditor(text: $viewModel.editText)
                        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 150, maxHeight: 150)
                        .background(Color.textBackground)
                        .foregroundColor(Color.textForeground)
                }
                .importCard()

                Spacer()

                Image(systemName: "qrcode.viewfinder")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor( .primaryOrange)
                    .importCard()
            }
            .padding(.horizontal, 24)

            WalletTextField(label: "Password", text: $viewModel.password1Text)
            .importCard()

            WalletTextField(label: "Confirm Password", text: $viewModel.password2Text)
            .importCard()

            HStack {
                Text("sign in with face ID")
                    .foregroundColor(Color.labelForeground)
                    .font(.system(size: 16, weight: .heavy))
                Spacer()
                Toggle("Face ID", isOn: $viewModel.faceIsOn)
                    .tint(Color.primaryOrange)
                            .labelsHidden()
            }
            .importCard()

            Text("Terms")
                .foregroundColor(.red)
            Spacer()
            WalletButton(title: "Import") {
                Task {
                    ethWallet = await viewModel.importWallet()
                }
                showView = false
            }
            .padding(.bottom, 42)
        }
        .background(Color.background)
    }
}

struct ImportCardify: ViewModifier {
    func body(content: Content) -> some View {
        HStack(alignment: .center) {
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cornerRadius(16)
        .background(Color.black.cornerRadius(16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 24/255, green: 30/255, blue: 37/255), lineWidth: 2)
        )
    }
}

extension View {
    func importCard() -> some View {
        modifier(ImportCardify())
    }
}

struct WalletTextField: View {
    var label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment:.leading) {
            Text(label)
                .foregroundColor(Color.labelForeground)
                .font(.system(size: 12, weight: .light))
                .padding(.bottom, 2)
            TextField("Password", text: $text)
                .padding()
                .background(Color.textBackground)
                .foregroundColor(Color.textForeground)
        }
    }
}

struct WalletButton: View {
    var title: String
    var background: Color = .primaryOrange
//    Color(red: 228/255, green: 86/255, blue: 4/255)
    var action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.system(size: 16.0, weight: .bold))
            Spacer()
        }
            .padding(16)
            .foregroundColor(.white)
            .background(background)
            .cornerRadius(168)
            .onTapGesture {
                action()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
    }
}

struct WalletImportView_Previews: PreviewProvider {
    static var previews: some View {
        WalletImportView(wallet: .constant(nil), showView: .constant(true))
            .preferredColorScheme(.dark)
    }
}
