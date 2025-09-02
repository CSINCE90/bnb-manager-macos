// ===== FILE 1: EnhancedDashboardView.swift (PRINCIPALE) =====
//  Mantieni solo la struttura principale, sposta tutto il resto in file separati

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
                // Nella tua Enhanced Dashboard, aggiungi:
                NavigationLink("🤖 AI Price Optimizer") {
                    PriceOptimizerView(viewModel: viewModel)
                }
                
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


