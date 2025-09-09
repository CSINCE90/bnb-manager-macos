// ===== SOSTITUISCI IL TUO ContentView.swift CON QUESTO =====

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GestionaleViewModel()
    @State private var selectedTab = 0
    @State private var useEnhancedViews = true
    @EnvironmentObject var localServer: LocalAPIServer
    @State private var bilancioFilterPrenotazioneId: UUID? = nil
    @State private var bilancioOpenAddOnAppear = false
    
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
            
            // Bilancio Tab (NUOVO!)
            BilancioView(viewModel: viewModel, filterPrenotazioneId: bilancioFilterPrenotazioneId, openAddOnAppear: bilancioOpenAddOnAppear)
                .tabItem {
                    Label("Bilancio", systemImage: "eurosign.circle")
                }
                .tag(2)
            
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
            .tag(3)
            
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
            .tag(4)
            
            // API Server Tab
            MockAPIServerView()
                .environmentObject(localServer)
                .tabItem {
                    Label("API Server", systemImage: localServer.isRunning ? "server.rack" : "xmark.server")
                }
                .tag(5)
            
            // ML PRICE OPTIMIZER TAB
            PriceOptimizerView(viewModel: viewModel)
                .tabItem {
                    Label("AI Prices", systemImage: "brain.head.profile")
                }
                .tag(6)
            
            // BOOKING INTEGRATION TAB
            BookingIntegrationView(viewModel: viewModel)
                .tabItem {
                    Label("Booking.com", systemImage: "building.2.crop.circle")
                }
                .tag(7)

            // STRUTTURE TAB
            StruttureView()
                .tabItem {
                    Label("Strutture", systemImage: "house.and.flag")
                }
                .tag(8)

            // PROFILO UTENTE TAB
            UserProfileView()
                .tabItem {
                    Label("Profilo", systemImage: "person.circle")
                }
                .tag(9)
        }
        .onAppear {
            viewModel.enableCoreData()
            localServer.configure(with: viewModel)
            localServer.startServer()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToCalendar"))) { _ in
            selectedTab = 4 // Aggiornato per il nuovo indice calendario
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToBilancio"))) { _ in
            selectedTab = 2 // Nuovo: navigazione verso Bilancio
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ActiveStrutturaChanged"))) { _ in
            // Aggiorna filtri e ricarica dati
            bilancioFilterPrenotazioneId = nil
            bilancioOpenAddOnAppear = false
            viewModel.caricaDatiDaCoreData()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToBilancioWithFilter"))) { note in
            if let id = note.userInfo?["prenotazioneId"] as? UUID {
                bilancioFilterPrenotazioneId = id
            }
            if let openAdd = note.userInfo?["openAddMovement"] as? Bool, openAdd == true {
                bilancioOpenAddOnAppear = true
            } else {
                bilancioOpenAddOnAppear = false
            }
            selectedTab = 2
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalAPIServer())
}
