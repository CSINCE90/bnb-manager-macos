//
//  HeaderSection.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE 2: Dashboard/Components/HeaderSection.swift =====

import SwiftUI

struct HeaderSection: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @Binding var selectedPeriod: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(getCurrentDate())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Period Selector
                Picker("Periodo", selection: $selectedPeriod) {
                    Text("Settimana").tag("Settimana")
                    Text("Mese").tag("Mese")
                    Text("Anno").tag("Anno")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Welcome message con statistiche rapide
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Profitto: **€\(String(format: "%.0f", viewModel.profittoNetto))**")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.profittoNetto > 0 {
                    Label("In crescita", systemImage: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                }
            }
        }
    }
    
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: Date()).capitalized
    }
}
