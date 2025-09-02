//
//  APIServerStatusView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE 4: Views/APIServer/APIServerStatusView.swift =====

import SwiftUI

struct APIServerStatusView: View {
    @EnvironmentObject var localServer: LocalAPIServer
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Status Header
                VStack(spacing: 16) {
                    Image(systemName: localServer.isRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(localServer.isRunning ? .green : .red)
                    
                    Text("Local API Server")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(localServer.isRunning ? "Running on \(localServer.serverURL)" : "Server Stopped")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Server Controls
                HStack(spacing: 20) {
                    Button(localServer.isRunning ? "🛑 Stop Server" : "🚀 Start Server") {
                        if localServer.isRunning {
                            localServer.stopServer()
                        } else {
                            localServer.startServer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if localServer.isRunning {
                        Button("📖 Open Documentation") {
                            if let url = URL(string: localServer.serverURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .controlSize(.large)
                    }
                }
                
                // Stats
                if localServer.isRunning {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Connected Clients:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(localServer.connectedClients)")
                                .fontWeight(.bold)
                                .foregroundColor(localServer.connectedClients > 0 ? .green : .secondary)
                        }
                        
                        HStack {
                            Text("Server URL:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(localServer.serverURL)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Quick Test Buttons
                if localServer.isRunning {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick API Tests:")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Button("📊 Status") {
                                openURL("/api/status")
                            }
                            
                            Button("📅 Bookings") {
                                openURL("/api/bookings")
                            }
                            
                            Button("📈 Analytics") {
                                openURL("/api/analytics")
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("API Server")
        }
    }
    
    private func openURL(_ path: String) {
        if let url = URL(string: localServer.serverURL + path) {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    APIServerStatusView()
        .environmentObject(LocalAPIServer())
}
