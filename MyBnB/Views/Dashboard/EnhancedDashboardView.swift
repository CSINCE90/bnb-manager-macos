//
//  EnhancedDashboardView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 29/08/25.
//

import SwiftUI
import Charts // Necessario per i grafici

struct EnhancedDashboardView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var selectedPeriod = "Mese"
    @State private var showingStats = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header migliorato
                HeaderSection(viewModel: viewModel, selectedPeriod: $selectedPeriod)
                    .padding(.horizontal)
                
                // KPI Cards animate
                if showingStats {
                    AnimatedKPICards(viewModel: viewModel)
                        .padding(.horizontal)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
                
                // Grafico Entrate (Nuovo!)
                RevenueChartSection(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Occupazione Visuale (Nuovo!)
                OccupancyVisualSection(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Prenotazioni Recenti Migliorate
                EnhancedRecentBookings(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Quick Actions con animazioni
                QuickActionsGrid(viewModel: viewModel)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Header Section
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

// MARK: - Animated KPI Cards
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

// MARK: - Modern KPI Card
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

// MARK: - Trend Indicator
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

// MARK: - Revenue Chart Section
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

// MARK: - Occupancy Visual Section
struct OccupancyVisualSection: View {
    @ObservedObject var viewModel: GestionaleViewModel
    
    var occupancyRate: Double {
        // Calcolo semplificato del tasso di occupazione
        let totalDays = 30.0
        let occupiedDays = Double(viewModel.prenotazioniAttive.count * 3) // Media 3 giorni per prenotazione
        return min((occupiedDays / totalDays) * 100, 100)
    }
    
    var occupancyColor: Color {
        switch occupancyRate {
        case 0..<40: return .red
        case 40..<70: return .orange
        default: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasso di Occupazione")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(occupancyRate))%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(occupancyColor)
            }
            
            HStack(spacing: 20) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(occupancyColor.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: occupancyRate / 100)
                        .stroke(occupancyColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: occupancyRate)
                    
                    VStack {
                        Text("\(Int(occupancyRate))%")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Occupato")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(label: "Check-in Oggi", value: "\(todayCheckIns())", color: .green)
                    StatRow(label: "Check-out Oggi", value: "\(todayCheckOuts())", color: .orange)
                    StatRow(label: "Camere Libere", value: "\(freeRooms())", color: .blue)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    private func todayCheckIns() -> Int {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni.filter {
            calendar.isDate($0.dataCheckIn, inSameDayAs: today)
        }.count
    }
    
    private func todayCheckOuts() -> Int {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni.filter {
            calendar.isDate($0.dataCheckOut, inSameDayAs: today)
        }.count
    }
    
    private func freeRooms() -> Int {
        // Assumiamo un totale di 5 camere
        let totalRooms = 5
        let occupiedRooms = viewModel.prenotazioniAttive.filter { prenotazione in
            let today = Date()
            return prenotazione.dataCheckIn <= today && prenotazione.dataCheckOut >= today
        }.count
        return max(totalRooms - occupiedRooms, 0)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Enhanced Recent Bookings
struct EnhancedRecentBookings: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var selectedBooking: Prenotazione?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Prenotazioni Recenti")
                    .font(.headline)
                
                Spacer()
                
                // Non usiamo NavigationLink ma un semplice testo
                if !viewModel.prenotazioniAttive.isEmpty {
                    Text("\(viewModel.prenotazioniAttive.count) attive")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.prenotazioniAttive.isEmpty {
                EmptyStateCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.prenotazioniAttive.prefix(5)) { prenotazione in
                            BookingCard(
                                prenotazione: prenotazione,
                                isSelected: selectedBooking?.id == prenotazione.id
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedBooking = prenotazione
                                }
                            }
                        }
                    }
                }
            }
            
            // Dettagli prenotazione selezionata
            if let booking = selectedBooking {
                BookingDetailCard(booking: booking)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
    }
}
struct BookingCard: View {
    let prenotazione: Prenotazione
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(prenotazione.statoPrenotazione.colore)
                    .frame(width: 10, height: 10)
                
                Text(prenotazione.nomeOspite)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Label(formatDate(prenotazione.dataCheckIn), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "person.2")
                        .font(.caption)
                    Text("\(prenotazione.numeroOspiti)")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("€\(Int(prenotazione.prezzoTotale))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : .black.opacity(0.05),
                       radius: isSelected ? 8 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

// MARK: - Booking Detail Card
struct BookingDetailCard: View {
    let booking: Prenotazione
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dettagli Prenotazione")
                .font(.callout)
                .fontWeight(.semibold)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Label("Ospite", systemImage: "person")
                        .foregroundColor(.secondary)
                    Text(booking.nomeOspite)
                        .fontWeight(.medium)
                }
                
                GridRow {
                    Label("Email", systemImage: "envelope")
                        .foregroundColor(.secondary)
                    Text(booking.email)
                        .font(.caption)
                }
                
                GridRow {
                    Label("Periodo", systemImage: "calendar")
                        .foregroundColor(.secondary)
                    Text("\(formatDate(booking.dataCheckIn)) - \(formatDate(booking.dataCheckOut))")
                }
                
                GridRow {
                    Label("Totale", systemImage: "eurosign")
                        .foregroundColor(.secondary)
                    Text("€\(String(format: "%.2f", booking.prezzoTotale))")
                        .fontWeight(.semibold)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Nessuna prenotazione attiva")
                .font(.headline)
            
            Text("Le nuove prenotazioni appariranno qui")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .foregroundColor(.secondary.opacity(0.3))
                )
        )
    }
}

// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var showingAddBooking = false
    @State private var showingAddExpense = false
    @State private var showingReport = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Azioni Rapide")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                QuickActionButton(
                    title: "Nuova Prenotazione",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: { showingAddBooking = true }
                )
                
                QuickActionButton(
                    title: "Aggiungi Spesa",
                    icon: "creditcard.fill",
                    color: .orange,
                    action: { showingAddExpense = true }
                )
                
                QuickActionButton(
                    title: "Genera Report",
                    icon: "doc.text.fill",
                    color: .purple,
                    action: { showingReport = true }
                )
                
                QuickActionButton(
                    title: "Calendario",
                    icon: "calendar",
                    color: .green,
                    action: { }
                )
                
                QuickActionButton(
                    title: "Statistiche",
                    icon: "chart.bar.fill",
                    color: .pink,
                    action: { }
                )
                
                QuickActionButton(
                    title: "Impostazioni",
                    icon: "gearshape.fill",
                    color: .gray,
                    action: { }
                )
            }
        }
        .sheet(isPresented: $showingAddBooking) {
            AggiungiPrenotazioneView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddExpense) {
            AggiungiSpesaView(viewModel: viewModel)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
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
