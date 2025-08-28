//
//  ContentView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GestionaleViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            PrenotazioniView(viewModel: viewModel)
                .tabItem {
                    Label("Prenotazioni", systemImage: "calendar")
                }
                .tag(1)
            
            SpeseView(viewModel: viewModel)
                .tabItem {
                    Label("Spese", systemImage: "creditcard")
                }
                .tag(2)
            
            CalendarioView(viewModel: viewModel)
                .tabItem {
                    Label("Calendario", systemImage: "calendar.badge.clock")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
