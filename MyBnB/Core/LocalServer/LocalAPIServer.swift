// ===== FILE 1: Core/LocalServer/LocalAPIServer.swift (VERSIONE SEMPLICE) =====


// ===== FIX 3: LocalAPIServer.swift (VERSIONE SENZA ERRORI RETE) =====

import SwiftUI
import Foundation

@MainActor
class LocalAPIServer: ObservableObject {
    @Published var isRunning = false
    @Published var serverURL = ""
    @Published var connectedClients: Int = 0
    
    private let port: UInt16 = 8765
    internal var httpServer: SimpleHTTPServer?  // Cambiato da private a internal
    
    // Riferimento al ViewModel
    private weak var viewModel: GestionaleViewModel?
    
    init() {
        serverURL = "http://localhost:\(port)"
    }
    
    func configure(with viewModel: GestionaleViewModel) {
        self.viewModel = viewModel
    }
    
    func startServer() {
        guard !isRunning else { return }
        
        httpServer = SimpleHTTPServer(port: Int(port))
        httpServer?.delegate = self
        
        if httpServer?.start() == true {
            isRunning = true
            print("🚀 Local API Server started on \(serverURL)")
        } else {
            print("❌ Failed to start server on port \(port)")
        }
    }
    
    func stopServer() {
        httpServer?.stop()
        httpServer = nil
        isRunning = false
        connectedClients = 0
        print("🛑 Server stopped")
    }
    
    // Metodo pubblico per testare le API
    func testEndpoint(_ path: String, method: String = "GET") -> String {
        return httpServer?.testRequest(path: path, method: method) ?? "Server not available"
    }
}

// MARK: - SimpleHTTPServer Delegate
extension LocalAPIServer: SimpleHTTPServerDelegate {
    func handleRequest(path: String, method: String) -> String {
        switch (method, path) {
        case ("GET", "/"):
            return createDocumentationHTML()
        case ("GET", "/docs"):
            return createDocumentationHTML()
        case ("GET", "/api/status"):
            return createStatusJSON()
        case ("GET", "/api/bookings"):
            return createBookingsJSON()
        case ("GET", "/api/analytics"):
            return createAnalyticsJSON()
        default:
            return createErrorJSON(404, "Not Found")
        }
    }
    
    private func createDocumentationHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>MyBnB API</title>
            <style>
                body { font-family: -apple-system, sans-serif; margin: 40px; background: #f5f5f7; }
                .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; }
                h1 { color: #1d1d1f; }
                .endpoint { background: #f5f5f7; padding: 20px; margin: 16px 0; border-radius: 8px; }
                .method { background: #007aff; color: white; padding: 4px 12px; border-radius: 16px; font-size: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🏠 MyBnB API Server</h1>
                <p>API locale per la gestione del B&B</p>
                
                <h2>Endpoints Disponibili</h2>
                
                <div class="endpoint">
                    <p><span class="method">GET</span> /api/status</p>
                    <p>Informazioni sullo stato del server</p>
                </div>
                
                <div class="endpoint">
                    <p><span class="method">GET</span> /api/bookings</p>
                    <p>Lista di tutte le prenotazioni</p>
                </div>
                
                <div class="endpoint">
                    <p><span class="method">GET</span> /api/analytics</p>
                    <p>Metriche e statistiche del business</p>
                </div>
                
                <h2>Test rapido</h2>
                <p><a href="/api/status">📊 Status del server</a></p>
                <p><a href="/api/bookings">📅 Tutte le prenotazioni</a></p>
                <p><a href="/api/analytics">📈 Analytics</a></p>
            </div>
        </body>
        </html>
        """
    }
    
    private func createStatusJSON() -> String {
        let status = [
            "server": "MyBnB Local API",
            "version": "1.0.0",
            "status": "running",
            "port": port,
            "uptime": Int(Date().timeIntervalSince1970)
        ] as [String: Any]
        
        return jsonResponse(status)
    }
    
    private func createBookingsJSON() -> String {
        guard let viewModel = viewModel else {
            return createErrorJSON(503, "Service Unavailable")
        }
        
        let bookings = viewModel.prenotazioni.map { booking in
            [
                "id": booking.id.uuidString,
                "guestName": booking.nomeOspite,
                "email": booking.email,
                "checkIn": ISO8601DateFormatter().string(from: booking.dataCheckIn),
                "checkOut": ISO8601DateFormatter().string(from: booking.dataCheckOut),
                "guests": booking.numeroOspiti,
                "totalPrice": booking.prezzoTotale,
                "status": booking.statoPrenotazione.rawValue
            ] as [String: Any]
        }
        
        let response = [
            "success": true,
            "count": bookings.count,
            "data": bookings
        ] as [String: Any]
        
        return jsonResponse(response)
    }
    
    private func createAnalyticsJSON() -> String {
        guard let viewModel = viewModel else {
            return createErrorJSON(503, "Service Unavailable")
        }
        
        let analytics = [
            "success": true,
            "data": [
                "totalRevenue": viewModel.entrateTotali,
                "totalExpenses": viewModel.speseTotali,
                "netProfit": viewModel.profittoNetto,
                "activeBookings": viewModel.prenotazioniAttive.count,
                "totalBookings": viewModel.prenotazioni.count
            ]
        ] as [String: Any]
        
        return jsonResponse(analytics)
    }
    
    private func jsonResponse(_ data: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"JSON encoding failed\"}"
        }
    }
    
    private func createErrorJSON(_ code: Int, _ message: String) -> String {
        let error = ["error": message, "code": code] as [String: Any]
        return jsonResponse(error)
    }
}
