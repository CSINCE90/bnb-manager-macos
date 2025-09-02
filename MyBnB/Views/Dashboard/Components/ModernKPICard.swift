//
//  ModernKPICard.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE MANCANTE 3: Dashboard/Components/ModernKPICard.swift =====

import SwiftUI

struct ModernKPICard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    let trend: Double?
    var isCount: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                
                Spacer()
                
                if let trend = trend {
                    TrendIndicator(value: trend)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if isCount {
                    Text("\(Int(value))")
                        .font(.title)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())
                } else {
                    Text("€\(Int(value))")
                        .font(.title)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: isHovered ? color.opacity(0.3) : .black.opacity(0.05),
                       radius: isHovered ? 12 : 4,
                       x: 0,
                       y: isHovered ? 6 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: isHovered ? 2 : 0)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct TrendIndicator: View {
    let value: Double
    
    var color: Color {
        value > 0 ? .green : .red
    }
    
    var icon: String {
        value > 0 ? "arrow.up.right" : "arrow.down.right"
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(abs(Int(value)))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}
