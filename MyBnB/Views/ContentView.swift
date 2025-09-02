// ===== SOSTITUISCI IL TUO ContentView.swift CON QUESTO =====

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GestionaleViewModel()
    @State private var selectedTab = 0
    @State private var useEnhancedViews = true
    @EnvironmentObject var localServer: LocalAPIServer
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            Group {
                if useEnhancedViews {
                    EnhancedDashboardView(viewModel: viewModel, selectedTab: $selectedTab)
                } else {
                    DashboardView(viewModel: viewModel)
                }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            // Prenotazioni Tab
            PrenotazioniView(viewModel: viewModel)
                .tabItem {
                    Label("Prenotazioni", systemImage: "calendar")
                }
                .tag(1)
            
            // Spese Tab
            Group {
                if useEnhancedViews {
                    EnhancedSpeseView(viewModel: viewModel)
                } else {
                    Text("Spese View")
                }
            }
            .tabItem {
                Label("Spese", systemImage: "creditcard")
            }
            .tag(2)
            
            // Calendario Tab
            Group {
                if useEnhancedViews {
                    EnhancedCalendarioView(viewModel: viewModel)
                } else {
                    CalendarioView(viewModel: viewModel)
                }
            }
            .tabItem {
                Label("Calendario", systemImage: "calendar.badge.clock")
            }
            .tag(3)
            
            // API Server Tab
            MockAPIServerView()
                .environmentObject(localServer)
                .tabItem {
                    Label("API Server", systemImage: localServer.isRunning ? "server.rack" : "xmark.server")
                }
                .tag(4)
            
            // ML PRICE OPTIMIZER TAB
            PriceOptimizerView(viewModel: viewModel)
                .tabItem {
                    Label("AI Prices", systemImage: "brain.head.profile")
                }
                .tag(5)
            
            // BOOKING INTEGRATION TAB (NUOVO!)
            BookingIntegrationView(viewModel: viewModel)
                .tabItem {
                    Label("Booking.com", systemImage: "building.2.crop.circle")
                }
                .tag(6)
        }
        .onAppear {
            viewModel.enableCoreData()
            localServer.configure(with: viewModel)
            localServer.startServer()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToCalendar"))) { _ in
            selectedTab = 3
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalAPIServer())
}
