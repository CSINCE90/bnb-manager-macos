//
//  EnhancedDashboardView.swift - VERSIONE CORRETTA
//  MyBnB
//

import SwiftUI
import Charts

struct EnhancedDashboardView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @Binding var selectedTab: Int
    @State private var selectedPeriod = "Mese"
    @State private var showingStats = true
    
    // Stati per le sheet
    @State private var showingAddBooking = false
    @State private var showingAddExpense = false
    @State private var showingReport = false
    @State private var showingStatistics = false
    @State private var showingSettings = false
    
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
                
                // Grafico Entrate
                RevenueChartSection(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Occupazione Visuale
                OccupancyVisualSection(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Prenotazioni Recenti
                EnhancedRecentBookings(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Quick Actions
                QuickActionsSection(
                    showingAddBooking: $showingAddBooking,
                    showingAddExpense: $showingAddExpense,
                    showingReport: $showingReport,
                    showingStatistics: $showingStatistics,
                    showingSettings: $showingSettings,
                    selectedTab: $selectedTab
                )
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
        .sheet(isPresented: $showingAddBooking) {
            AggiungiPrenotazioneView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddExpense) {
            AggiungiSpesaView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingReport) {
            ReportView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 500)
        }
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
    
    // Configurazione personalizzabile - puoi cambiarla o leggerla da UserDefaults
    @AppStorage("totalBeds") private var totalBeds = 4  // Posti letto totali
    @AppStorage("accommodationType") private var accommodationType = "B&B"  // Tipo struttura
    @State private var showingSettings = false
    
    // Calcolo occupazione basato sui posti letto
    var occupiedBeds: Int {
        let today = Date()
        return viewModel.prenotazioniAttive
            .filter { prenotazione in
                prenotazione.dataCheckIn <= today && prenotazione.dataCheckOut >= today
            }
            .reduce(0) { $0 + $1.numeroOspiti }  // Somma gli ospiti attuali
    }
    
    var availableBeds: Int {
        max(totalBeds - occupiedBeds, 0)
    }
    
    var occupancyRate: Double {
        guard totalBeds > 0 else { return 0 }
        return (Double(occupiedBeds) / Double(totalBeds)) * 100
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
            // Header con impostazioni
            HStack {
                Text("Stato Occupazione")
                    .font(.headline)
                
                Spacer()
                
                // Badge con tipo struttura
                Text(accommodationType)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                
                // Bottone impostazioni
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int(occupancyRate))%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(occupancyColor)
            }
            
            HStack(spacing: 20) {
                // Grafico circolare
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(occupancyColor.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: occupancyRate / 100)
                        .stroke(occupancyColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: occupancyRate)
                    
                    // Centro con info
                    VStack(spacing: 2) {
                        Text("\(occupiedBeds)/\(totalBeds)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("posti letto")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Statistiche dettagliate
                VStack(alignment: .leading, spacing: 12) {
                    // Check-in oggi
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Check-in Oggi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(todayCheckIns()) ospiti")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    
                    // Check-out oggi
                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text("Check-out Oggi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(todayCheckOuts()) ospiti")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    
                    // Posti disponibili
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text("Posti Disponibili")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(availableBeds)")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(availableBeds == 0 ? .red : .primary)
                    }
                }
                
                Spacer()
                
                // Visual dei posti letto
                VStack(alignment: .leading, spacing: 8) {
                    Text("Situazione Posti")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 30))
                    ], spacing: 8) {
                        ForEach(0..<totalBeds, id: \.self) { index in
                            Image(systemName: index < occupiedBeds ? "bed.double.fill" : "bed.double")
                                .font(.title2)
                                .foregroundColor(index < occupiedBeds ? occupancyColor : .gray.opacity(0.3))
                        }
                    }
                    .frame(maxWidth: 150)
                    
                    if occupancyRate >= 100 {
                        Text("Completo!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    } else if availableBeds == 1 {
                        Text("Ultimo posto!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .sheet(isPresented: $showingSettings) {
            OccupancySettingsView(totalBeds: $totalBeds, accommodationType: $accommodationType)
        }
    }
    
    // Calcola ospiti in check-in oggi
    private func todayCheckIns() -> Int {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni
            .filter { calendar.isDate($0.dataCheckIn, inSameDayAs: today) }
            .reduce(0) { $0 + $1.numeroOspiti }
    }
    
    // Calcola ospiti in check-out oggi
    private func todayCheckOuts() -> Int {
        let calendar = Calendar.current
        let today = Date()
        return viewModel.prenotazioni
            .filter { calendar.isDate($0.dataCheckOut, inSameDayAs: today) }
            .reduce(0) { $0 + $1.numeroOspiti }
    }
}

// MARK: - Occupancy Settings View
struct OccupancySettingsView: View {
    @Binding var totalBeds: Int
    @Binding var accommodationType: String
    @Environment(\.dismiss) private var dismiss
    
    let accommodationTypes = ["B&B", "Casa Vacanze", "Affittacamere", "Guest House", "Ostello", "Appartamento"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Impostazioni Struttura")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                // Tipo struttura
                Section("Tipo di Struttura") {
                    Picker("Tipo", selection: $accommodationType) {
                        ForEach(accommodationTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Posti letto
                Section("Capacità") {
                    HStack {
                        Text("Posti Letto Totali")
                        Spacer()
                        Stepper("\(totalBeds)", value: $totalBeds, in: 1...20)
                    }
                    
                    Text("Imposta il numero totale di posti letto disponibili nella tua struttura")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Anteprima
                Section("Anteprima") {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.blue)
                        Text("\(totalBeds) posti letto in \(accommodationType)")
                    }
                }
            }
            .frame(height: 250)
            
            HStack {
                Button("Annulla") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Salva") {
                    // Le modifiche sono già salvate tramite @AppStorage
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - StatRowItem (se non esiste già)
struct StatRowItem: View {
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

// MARK: - Booking Card
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
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Ospite", systemImage: "person")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text(booking.nomeOspite)
                        .fontWeight(.medium)
                        .font(.caption)
                }
                
                HStack {
                    Label("Email", systemImage: "envelope")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text(booking.email)
                        .font(.caption)
                }
                
                HStack {
                    Label("Periodo", systemImage: "calendar")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text("\(formatDate(booking.dataCheckIn)) - \(formatDate(booking.dataCheckOut))")
                        .font(.caption)
                }
                
                HStack {
                    Label("Totale", systemImage: "eurosign")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                    Text("€\(String(format: "%.2f", booking.prezzoTotale))")
                        .fontWeight(.semibold)
                        .font(.caption)
                }
            }
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

// MARK: - Quick Actions Section
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

// MARK: - Quick Action Button Simple
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


// MARK: - Export Manager
import AppKit

struct ExportManager {
    static func exportAsPDF() {
        let savePanel = NSSavePanel()
        savePanel.title = "Esporta PDF"
        savePanel.allowedFileTypes = ["pdf"]
        savePanel.nameFieldStringValue = "report.pdf"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let pdfContent = "Report MyBnB - dati fittizi"
            let data = pdfContent.data(using: .utf8)!
            do {
                try data.write(to: url)
                print("PDF esportato in: \(url.path)")
            } catch {
                print("Errore esportazione PDF: \(error.localizedDescription)")
            }
        }
    }
    
    static func exportAsCSV() {
        let savePanel = NSSavePanel()
        savePanel.title = "Esporta CSV"
        savePanel.allowedFileTypes = ["csv"]
        savePanel.nameFieldStringValue = "dati.csv"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let csvContent = "Nome,CheckIn,CheckOut,Prezzo\nMario Rossi,01/09/2025,05/09/2025,250"
            let data = csvContent.data(using: .utf8)!
            do {
                try data.write(to: url)
                print("CSV esportato in: \(url.path)")
            } catch {
                print("Errore esportazione CSV: \(error.localizedDescription)")
            }
        }
    }
    
    static func exportAsJSON() {
        let savePanel = NSSavePanel()
        savePanel.title = "Esporta JSON"
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "dati.json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let jsonContent = """
            {
                "prenotazioni": [
                    { "nome": "Mario Rossi", "checkIn": "2025-09-01", "checkOut": "2025-09-05", "prezzo": 250 }
                ]
            }
            """
            let data = jsonContent.data(using: .utf8)!
            do {
                try data.write(to: url)
                print("JSON esportato in: \(url.path)")
            } catch {
                print("Errore esportazione JSON: \(error.localizedDescription)")
            }
        }
    }
}


