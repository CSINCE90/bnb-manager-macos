//
//  APIServerView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 31/08/25.
//

// ===== FILE 4: Views/APIServer/APIServerView.swift =====

import SwiftUI

struct APIServerView: View {
    @EnvironmentObject var localServer: LocalAPIServer
    @State private var showingLogs = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Server Status Card
                ServerStatusCard(server: localServer)
                
                // Quick Actions
                HStack(spacing: 16) {
                    Button(action: {
                        if let url = URL(string: localServer.serverURL + "/docs") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("Open Documentation", systemImage: "doc.text")
                    }
                    .disabled(!localServer.isRunning)
                    
                    Button(action: {
                        if let url = URL(string: localServer.serverURL + "/api/status") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("API Status", systemImage: "info.circle")
                    }
                    .disabled(!localServer.isRunning)
                    
                    Button(action: { showingLogs.toggle() }) {
                        Label("View Logs", systemImage: "list.bullet.rectangle")
                    }
                }
                
                // API Endpoints List
                APIEndpointsList()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Local API Server")
        }
        .sheet(isPresented: $showingLogs) {
            APILogsView()
        }
    }
}

struct ServerStatusCard: View {
    @ObservedObject var server: LocalAPIServer
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: server.isRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(server.isRunning ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text("API Server")
                        .font(.headline)
                    Text(server.isRunning ? "Running" : "Stopped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(server.isRunning ? "Stop" : "Start") {
                    if server.isRunning {
                        server.stopServer()
                    } else {
                        server.startServer()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            if server.isRunning {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("URL:")
                            .foregroundColor(.secondary)
                        Text(server.serverURL)
                            .fontWeight(.medium)
                            .textSelection(.enabled)
                        
                        Spacer()
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(server.serverURL, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    
                    HStack {
                        Text("Connected Clients:")
                            .foregroundColor(.secondary)
                        Text("\(server.connectedClients)")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Circle()
                            .fill(server.connectedClients > 0 ? .green : .gray)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct APIEndpointsList: View {
    let endpoints = [
        ("GET", "/api/bookings", "Ottieni tutte le prenotazioni"),
        ("POST", "/api/bookings", "Crea una nuova prenotazione"),
        ("GET", "/api/expenses", "Ottieni tutte le spese"),
        ("POST", "/api/expenses", "Crea una nuova spesa"),
        ("GET", "/api/analytics", "Metriche di business"),
        ("GET", "/api/status", "Stato del server"),
        ("GET", "/docs", "Documentazione API")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Endpoints")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(endpoints, id: \.0) { method, path, description in
                    HStack {
                        Text(method)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(methodColor(method))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        
                        Text(path)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .gray
        }
    }
}

struct APILogsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🚀 Server started on http://localhost:8765")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("📡 Waiting for connections...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    // Mock logs - in production, you'd have a real logging system
                    Text("✅ GET /api/bookings - 200 OK")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text("✅ POST /api/bookings - 201 Created")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("API Logs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
