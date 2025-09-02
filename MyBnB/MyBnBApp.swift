//
//  MyBnBApp.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//
// ===== FIX 5: MyBnBApp.swift (VERSIONE SICURA) =====

import SwiftUI

@main
struct MyBnBApp: App {
    @StateObject private var localServer = LocalAPIServer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localServer)
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("📖 API Documentation (Mock)") {
                    // Per ora apriamo una finestra con la documentazione
                    showMockDocumentation()
                }
                
                Button(localServer.isRunning ? "🛑 Stop Mock Server" : "🚀 Start Mock Server") {
                    if localServer.isRunning {
                        localServer.stopServer()
                    } else {
                        localServer.startServer()
                    }
                }
            }
        }
    }
    
    private func showMockDocumentation() {
        let alert = NSAlert()
        alert.messageText = "MyBnB API Documentation"
        alert.informativeText = """
        Mock API Server Running
        
        Available Endpoints:
        • GET /api/status
        • GET /api/bookings  
        • GET /api/analytics
        
        Note: This is a mock implementation for demo purposes.
        """
        alert.runModal()
    }
}
