//
//  AboutView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 30/08/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Icona/logo
            Image(systemName: "house.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            // Titolo app
            Text("MyBnB")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Versione 2.0")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Autocelebrazione 😎
            VStack(spacing: 8) {
                Text("Developer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Francesco Chifari")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Software Engineer|Backend and DevOps")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Contatti
            VStack(spacing: 6) {
                Link("🌐 GitHub", destination: URL(string: "https://github.com/CSINCE90")!)
                Link("💼 LinkedIn", destination: URL(string: "https://www.linkedin.com/in/francesco-chifari")!)
                Link("📧 Email", destination: URL(string: "mailto:f.chifari32@gmail.com")!)
            }
            .font(.footnote)
            .padding(.bottom, 8)
            
            Button("Chiudi") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(minWidth: 420, minHeight: 380)
    }
}
