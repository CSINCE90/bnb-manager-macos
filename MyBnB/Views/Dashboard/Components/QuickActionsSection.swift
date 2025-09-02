//
//  QuickActionsSection.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE 9: Dashboard/Components/QuickActionsSection.swift =====

import SwiftUI

struct QuickActionsSection: View {
    @Binding var showingAddBooking: Bool
    @Binding var showingAddExpense: Bool
    @Binding var showingReport: Bool
    @Binding var showingStatistics: Bool
    @Binding var showingSettings: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Azioni Rapide")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                QuickActionButtonSimple(
                    title: "Nuova Prenotazione",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: { showingAddBooking = true }
                )
                
                QuickActionButtonSimple(
                    title: "Aggiungi Spesa",
                    icon: "creditcard.fill",
                    color: .orange,
                    action: { showingAddExpense = true }
                )
                
                QuickActionButtonSimple(
                    title: "Genera Report",
                    icon: "doc.text.fill",
                    color: .purple,
                    action: { showingReport = true }
                )
                
                QuickActionButtonSimple(
                    title: "Calendario",
                    icon: "calendar",
                    color: .green,
                    action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("NavigateToCalendar"),
                            object: nil
                        )
                    }
                )
                
                QuickActionButtonSimple(
                    title: "Statistiche",
                    icon: "chart.bar.fill",
                    color: .pink,
                    action: { showingStatistics = true }
                )
                
                QuickActionButtonSimple(
                    title: "Impostazioni",
                    icon: "gearshape.fill",
                    color: .gray,
                    action: { showingSettings = true }
                )
            }
        }
    }
}

struct QuickActionButtonSimple: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: isPressed ? .clear : .black.opacity(0.05),
                           radius: isPressed ? 0 : 4,
                           y: isPressed ? 0 : 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
