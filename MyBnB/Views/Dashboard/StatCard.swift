//
//  StatCard.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor.gradient) // Usa Color invece di UIColor
        )
        .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// Esempio di utilizzo con colori SwiftUI
#Preview {
    HStack(spacing: 16) {
        StatCard(
            title: "Prenotazioni Attive",
            value: "12",
            systemImage: "calendar.badge.clock",
            backgroundColor: .blue
        )
        
        StatCard(
            title: "Entrate Totali",
            value: "€2,450",
            systemImage: "eurosign.circle.fill",
            backgroundColor: .green
        )
        
        StatCard(
            title: "Profitto Netto",
            value: "€1,890",
            systemImage: "chart.line.uptrend.xyaxis",
            backgroundColor: .purple
        )
    }
    .padding()
}
