//
//  AnimatedKPICard.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//
// ===== FILE MANCANTE 2: Dashboard/Components/AnimatedKPICards.swift =====

import SwiftUI

struct AnimatedKPICards: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var animateValues = false
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            
            ModernKPICard(
                title: "Entrate",
                value: animateValues ? viewModel.entrateTotali : 0,
                icon: "eurosign.circle.fill",
                color: .green,
                trend: 12.5
            )
            
            ModernKPICard(
                title: "Spese",
                value: animateValues ? viewModel.speseTotali : 0,
                icon: "creditcard.fill",
                color: .red,
                trend: -5.2
            )
            
            ModernKPICard(
                title: "Profitto",
                value: animateValues ? viewModel.profittoNetto : 0,
                icon: "chart.line.uptrend.xyaxis",
                color: viewModel.profittoNetto > 0 ? .blue : .orange,
                trend: viewModel.profittoNetto > 0 ? 8.3 : -3.1
            )
            
            ModernKPICard(
                title: "Prenotazioni",
                value: Double(viewModel.prenotazioniAttive.count),
                icon: "calendar.badge.clock",
                color: .purple,
                trend: nil,
                isCount: true
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateValues = true
            }
        }
    }
}
