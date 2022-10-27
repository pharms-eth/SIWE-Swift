//
//  ContentView.swift
//  SIWE-Swift
//
//  Created by Daniel Bell on 2/5/22.
//

import SwiftUI
import web3swift

struct WalletSetupMenuView: View {

    @State private var showingCreatePopover = false
    @State private var showingImportPopover = false
    @Binding public var wallet: Wallet?

    var body: some View {
        VStack(alignment: .center){
            Spacer()
            Image(systemName: "creditcard")
                .resizable()
                .frame(width: 250, height: 250)
            Spacer()
            VStack {
                Text(wallet?.address.address ?? "Wallet Setup")
                    .font(.system(size: wallet == nil ? 40.0 : 16.0, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.vertical, 28)
                    .padding(.horizontal, 40)

//                WalletSetupStyledButton(showingPopover: $showingImportPopover, title: "Import Using Seed Phrase", background: Color(red: 32/255, green: 40/255, blue: 50/255)) {
                    WalletImportView(wallet: $wallet, showView: $showingImportPopover)
//                }
            }
            .padding(.bottom, 56)
        }
    }
}

struct WalletSetupStyledButton<Content: View>: View {

    @Binding public var showingPopover: Bool
    var title: String
    var background: Color
    var content: () -> Content

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
                showingPopover.toggle()
            }
            .popover(isPresented: $showingPopover) {
                content()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletSetupMenuView(wallet: .constant(nil))
    }
}


struct SheetView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Button("Press to dismiss") {
            dismiss()
        }
        .font(.title)
        .padding()
        .background(Color.black)
    }
}
