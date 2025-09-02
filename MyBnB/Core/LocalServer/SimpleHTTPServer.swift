//
//  SimpleHTTPServer.swift
//  MyBnB
//
//  Created by Francesco Chifari on 01/09/25.
//

// ===== FIX 4: SimpleHTTPServer.swift (NUOVO FILE) =====

import Foundation
import Network

protocol SimpleHTTPServerDelegate: AnyObject {
    func handleRequest(path: String, method: String) -> String
}

class SimpleHTTPServer {
    weak var delegate: SimpleHTTPServerDelegate?
    private let port: Int
    private var isRunning = false
    
    init(port: Int) {
        self.port = port
    }
    
    func start() -> Bool {
        // Per semplicità, usiamo un mock server che simula le risposte
        // In un'app reale, useresti NWListener o un framework come Vapor
        isRunning = true
        
        // Simula il server in background
        DispatchQueue.global().async {
            print("🎭 Mock HTTP Server running on port \(self.port)")
            print("📝 In una versione completa, qui ci sarebbe NWListener")
        }
        
        return true
    }
    
    func stop() {
        isRunning = false
    }
    
    // Metodo per testare manualmente le risposte
    func testRequest(path: String, method: String = "GET") -> String {
        return delegate?.handleRequest(path: path, method: method) ?? "No delegate"
    }
}

