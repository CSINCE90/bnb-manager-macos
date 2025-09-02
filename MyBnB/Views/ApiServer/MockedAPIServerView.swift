//
//  MockedAPIServerView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 01/09/25.
//
// ===== FIX 7: Views/APIServer/MockAPIServerView.swift =====

import SwiftUI

struct MockAPIServerView: View {
    @EnvironmentObject var localServer: LocalAPIServer
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Status Header
                VStack(spacing: 16) {
                    Image(systemName: localServer.isRunning ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(localServer.isRunning ? .green : .red)
                    
                    Text("Mock API Server")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(localServer.isRunning ? "Mock server running" : "Server stopped")
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
                }
                
                // API Test Buttons
                if localServer.isRunning {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test API Endpoints:")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Button("📊 Test Status") {
                                testAPI("/api/status")
                            }
                            
                            Button("📅 Test Bookings") {
                                testAPI("/api/bookings")
                            }
                            
                            Button("📈 Test Analytics") {
                                testAPI("/api/analytics")
                            }
                        }
                    }
                    
                    // Test Results
                    if !testResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Test Results:")
                                    .font(.headline)
                                
                                ForEach(testResults.indices, id: \.self) { index in
                                    Text(testResults[index])
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(8)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("API Server")
        }
    }
    
    private func testAPI(_ endpoint: String) {
        let mockServer = localServer.httpServer
        let result = mockServer?.testRequest(path: endpoint) ?? "Server not available"
        testResults.append("GET \(endpoint): \(result.prefix(100))...")
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalAPIServer())
}
