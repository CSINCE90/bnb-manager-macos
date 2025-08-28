//
//  SpeseView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct SpeseView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var mostraAggiungiSpesa = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.spese.sorted { $0.data > $1.data }) { spesa in
                    SpesaCardView(spesa: spesa)
                }
                .onDelete(perform: viewModel.eliminaSpesa)
            }
            .navigationTitle("Spese")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        mostraAggiungiSpesa = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostraAggiungiSpesa) {
                AggiungiSpesaView(viewModel: viewModel)
            }
        }
    }
}

struct SpesaCardView: View {
    let spesa: Spesa
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(spesa.descrizione)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "€%.2f", spesa.importo))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            
            HStack {
                Text(spesa.categoria.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                Spacer()
                
                Text(dateFormatter.string(from: spesa.data))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    SpeseView(viewModel: GestionaleViewModel())
}
