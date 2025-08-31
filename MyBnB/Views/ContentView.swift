//
//  ContentView.swift
//  MyBnB
//
//  VERSIONE CORRETTA - Sintassi sistemata
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GestionaleViewModel()
    @State private var selectedTab = 0
    @State private var useEnhancedViews = true
    
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
                    //SpeseView(viewModel: viewModel)
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
        }
        .onAppear {
            viewModel.enableCoreData()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToCalendar"))) { _ in
            selectedTab = 3
        }
    }
}

#Preview {
    ContentView()
}
