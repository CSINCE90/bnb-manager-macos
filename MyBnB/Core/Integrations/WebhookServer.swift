// ===== FILE 2: Core/Integrations/WebhookServer.swift =====

import Foundation

protocol WebhookServerDelegate: AnyObject {
    func didReceiveWebhook(data: [String: Any])
}

class WebhookServer {
    weak var delegate: WebhookServerDelegate?
    private let port: Int
    private var isRunning = false
    
    init(port: Int) {
        self.port = port
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        print("🌐 Webhook server mock started on port \(port)")
        
        // Simula webhook server
        // In un'implementazione reale, useresti NWListener o Vapor
        simulateWebhookReceiving()
    }
    
    func stop() {
        isRunning = false
        print("🛑 Webhook server stopped")
    }
    
    private func simulateWebhookReceiving() {
        // Simula ricezione webhook dopo 10 secondi
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            guard self.isRunning else { return }
            
            let mockWebhookData: [String: Any] = [
                "booking_id": "BK789456",
                "guest_name": "Giuseppe Verdi",
                "email": "giuseppe.verdi@email.com",
                "phone": "+39 347 1234567",
                "check_in": "2024-09-15",
                "check_out": "2024-09-18",
                "guests": 2,
                "total_price": 280.0,
                "special_requests": "Vegetarian breakfast requested"
            ]
            
            DispatchQueue.main.async {
                self.delegate?.didReceiveWebhook(data: mockWebhookData)
            }
        }
    }
}
