//
//  RevenueChartSection.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE 5: Dashboard/Components/RevenueChartSection.swift =====

import SwiftUI
import Charts

struct RevenueChartSection: View {
    @ObservedObject var viewModel: GestionaleViewModel
    
    // Dati simulati per il grafico
    let last7Days = [
        (day: "Lun", revenue: 250.0),
        (day: "Mar", revenue: 180.0),
        (day: "Mer", revenue: 320.0),
        (day: "Gio", revenue: 280.0),
        (day: "Ven", revenue: 450.0),
        (day: "Sab", revenue: 520.0),
        (day: "Dom", revenue: 380.0)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Andamento Settimanale")
                    .font(.headline)
                
                Spacer()
                
                Text("€\(Int(last7Days.reduce(0) { $0 + $1.revenue }))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Chart(last7Days, id: \.day) { item in
                LineMark(
                    x: .value("Giorno", item.day),
                    y: .value("Entrate", item.revenue)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Giorno", item.day),
                    y: .value("Entrate", item.revenue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                PointMark(
                    x: .value("Giorno", item.day),
                    y: .value("Entrate", item.revenue)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(60)
            }
            .frame(height: 200)
            .chartYAxisLabel("Entrate (€)")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

