import Foundation
import SwiftUI

@MainActor
class BookingIntegrationService: ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var lastSync: Date?
    @Published var pendingBookings: [BookingReservation] = []
    @Published var syncLogs: [SyncLog] = []
    
    private let webhookPort: Int = 8766 // Porta diversa dal server principale
    private var webhookServer: WebhookServer?
    
    // Configurazione dinamica letta da Strutture (AppStorage)
    struct BookingConfig {
        let propertyId: String
        let propertyName: String
        let location: String
        let webhookUrl: String
        let apiKey: String
        let bookingUrl: String
    }
    
    private var config: BookingConfig {
        let propertyId = (UserDefaults.standard.string(forKey: "activeBookingPropertyId") ?? "").isEmpty ? "demo_property" : (UserDefaults.standard.string(forKey: "activeBookingPropertyId") ?? "")
        let propertyName = UserDefaults.standard.string(forKey: "activeStrutturaName") ?? "Struttura"
        let bookingUrl = (UserDefaults.standard.string(forKey: "activeBookingUrl") ?? "").isEmpty ? "https://www.booking.com" : (UserDefaults.standard.string(forKey: "activeBookingUrl") ?? "https://www.booking.com")
        return BookingConfig(
            propertyId: propertyId,
            propertyName: propertyName,
            location: "Italia",
            webhookUrl: "http://localhost:8766/webhook/booking",
            apiKey: "demo_api_key",
            bookingUrl: bookingUrl
        )
    }
    
    init() {
        startWebhookServer()
        simulateExistingBookings() // Per demo
    }
    
    // MARK: - Public Methods
    
    func connectToBooking() async {
        connectionStatus = "Connecting..."
        
        // Simula connessione API
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondi
        
        // Simula successo
        isConnected = true
        connectionStatus = "Connected to Booking.com"
        lastSync = Date()
        
        addSyncLog("✅ Successfully connected to Booking.com")
        let cfg = config
        addSyncLog("🏠 Property: \(cfg.propertyName) - \(cfg.location)")
        addSyncLog("🆔 Property ID: \(cfg.propertyId)")
        addSyncLog("🔗 Webhook URL configured: \(cfg.webhookUrl)")
        addSyncLog("🌐 Booking URL: \(cfg.bookingUrl)")
        
        // Simula sync iniziale
        await performInitialSync()
    }
    
    func disconnect() {
        isConnected = false
        connectionStatus = "Disconnected"
        webhookServer?.stop()
        addSyncLog("❌ Disconnected from Booking.com")
    }
    
    func manualSync() async {
        guard isConnected else { return }
        
        addSyncLog("🔄 Manual sync started...")
        
        // Simula fetch nuove prenotazioni
        let newBookings = await fetchNewBookings()
        
        for booking in newBookings {
            pendingBookings.append(booking)
            addSyncLog("📥 New booking received: \(booking.guestName)")
        }
        
        lastSync = Date()
        addSyncLog("✅ Sync completed - \(newBookings.count) new bookings")
    }
    
    func approveBooking(_ booking: BookingReservation) {
        // Rimuovi da pending
        pendingBookings.removeAll { $0.id == booking.id }
        
        var convertedBooking = convertToLocalBooking(booking)
        convertedBooking.note += "\n🏠 La Casetta delle Petunie - Sicilia"
        
        // Notifica che è stata approvata (verrà gestita dal ViewModel)
        NotificationCenter.default.post(
            name: .bookingApproved,
            object: convertedBooking
        )
        
        addSyncLog("✅ Booking approved: \(booking.guestName)")
    }
    
    func rejectBooking(_ booking: BookingReservation, reason: String) {
        pendingBookings.removeAll { $0.id == booking.id }
        addSyncLog("❌ Booking rejected: \(booking.guestName) - Reason: \(reason)")
    }
    
    // MARK: - Private Methods
    
    private func startWebhookServer() {
        webhookServer = WebhookServer(port: webhookPort)
        webhookServer?.delegate = self
        webhookServer?.start()
        addSyncLog("🌐 Webhook server started on port \(webhookPort)")
    }
    
    private func performInitialSync() async {
        addSyncLog("🔄 Performing initial sync...")
        
        // Simula caricamento prenotazioni esistenti
        let existingBookings = await fetchExistingBookings()
        
        addSyncLog("📊 Found \(existingBookings.count) existing bookings")
        addSyncLog("✅ Initial sync completed")
    }
    
    private func fetchNewBookings() async -> [BookingReservation] {
        // Simula API call a Booking.com
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 secondo
        
        // Genera prenotazioni simulate casuali
        return generateMockBookings(count: Int.random(in: 0...2))
    }
    
    private func fetchExistingBookings() async -> [BookingReservation] {
        // Simula fetch delle prenotazioni esistenti
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 secondi
        return []
    }
    
    private func generateMockBookings(count: Int) -> [BookingReservation] {
        // Nomi tipici di ospiti che prenotano case vacanze in Sicilia
        let mockGuests = [
            "Marco Santangelo", "Elena Russo", "Giuseppe Bianchi",
            "Anna Lombardi", "Francesco Romano", "Giulia Conti",
            "Davide Esposito", "Valentina Costa", "Andrea Ricci",
            "Chiara Fontana", "Roberto Galli", "Federica Marino"
        ]
        
        let mockEmails = [
            "marco.santangelo@gmail.com", "elena.russo@yahoo.it", "giuseppe.b@libero.it",
            "anna.lombardi@outlook.com", "francesco.romano@gmail.com", "giulia.conti@alice.it",
            "davide.e@hotmail.com", "valentina.costa@gmail.com", "andrea.ricci@virgilio.it",
            "chiara.fontana@tin.it", "roberto.galli@gmail.com", "federica.marino@email.it"
        ]
        
        var bookings: [BookingReservation] = []
        
        for i in 0..<count {
            let randomIndex = Int.random(in: 0..<mockGuests.count)
            let checkIn = Date().addingTimeInterval(TimeInterval.random(in: 86400...30*86400)) // 1-30 giorni
            let nights = Int.random(in: 2...7)
            let checkOut = checkIn.addingTimeInterval(TimeInterval(nights * 86400))
            
            // Prezzi realistici per case vacanze in Sicilia
            let basePrice = Double.random(in: 80...150) // Prezzo per notte
            let totalPrice = basePrice * Double(nights)
            
            // Richieste speciali tipiche per Sicilia
            let specialRequests = [
                "Arrivare in tarda serata, possibile?",
                "Informazioni sui trasporti per l'aeroporto",
                "Colazione senza glutine per favore",
                "Servizio navetta per la spiaggia?",
                "Possiamo parcheggiare gratuitamente?",
                nil, nil, nil // Molte prenotazioni senza richieste
            ]
            
            let booking = BookingReservation(
                bookingId: "BK\(Int.random(in: 100000...999999))",
                guestName: mockGuests[randomIndex],
                email: mockEmails[randomIndex],
                phone: "+39 3\(Int.random(in: 10...99)) \(Int.random(in: 1000000...9999999))",
                checkIn: checkIn,
                checkOut: checkOut,
                guests: Int.random(in: 1...4),
                totalPrice: totalPrice,
                source: "Booking.com",
                status: .pending,
                specialRequests: specialRequests.randomElement() ?? nil
            )
            
            bookings.append(booking)
        }
        
        return bookings
    }
    
    private func convertToLocalBooking(_ booking: BookingReservation) -> Prenotazione {
        return Prenotazione(
            strutturaId: UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? ""),
            nomeOspite: booking.guestName,
            email: booking.email,
            telefono: booking.phone,
            dataCheckIn: booking.checkIn,
            dataCheckOut: booking.checkOut,
            numeroOspiti: booking.guests,
            prezzoTotale: booking.totalPrice,
            statoPrenotazione: .confermata,
            note: "Source: \(booking.source)\nBooking ID: \(booking.bookingId)\n\(booking.specialRequests ?? "")"
        )
    }
    
    private func addSyncLog(_ message: String) {
        let log = SyncLog(message: message, timestamp: Date())
        syncLogs.insert(log, at: 0) // Aggiungi in cima
        
        // Mantieni solo gli ultimi 50 log
        if syncLogs.count > 50 {
            syncLogs = Array(syncLogs.prefix(50))
        }
    }
    
    private func simulateExistingBookings() {
        // Per demo, simula alcune prenotazioni pending
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.pendingBookings = self.generateMockBookings(count: 2)
            self.addSyncLog("📥 Received \(self.pendingBookings.count) new booking notifications")
        }
    }
}

// MARK: - Webhook Server Delegate
extension BookingIntegrationService: WebhookServerDelegate {
    func didReceiveWebhook(data: [String: Any]) {
        addSyncLog("🔔 Webhook received from Booking.com")
        
        // Processa webhook data
        if let bookingData = parseWebhookData(data) {
            pendingBookings.append(bookingData)
            addSyncLog("📥 New booking via webhook: \(bookingData.guestName)")
            
            // Invia notifica locale
            sendLocalNotification(for: bookingData)
        }
    }
    
    private func parseWebhookData(_ data: [String: Any]) -> BookingReservation? {
        // Simula parsing dei dati webhook di Booking.com
        guard let guestName = data["guest_name"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        
        return BookingReservation(
            bookingId: data["booking_id"] as? String ?? "WEBHOOK_\(UUID().uuidString.prefix(8))",
            guestName: guestName,
            email: email,
            phone: data["phone"] as? String ?? "",
            checkIn: Date(),
            checkOut: Date().addingTimeInterval(3 * 86400),
            guests: data["guests"] as? Int ?? 2,
            totalPrice: data["total_price"] as? Double ?? 200.0,
            source: "Booking.com",
            status: .pending,
            specialRequests: data["special_requests"] as? String
        )
    }
    
    private func sendLocalNotification(for booking: BookingReservation) {
        // Invia notifica macOS personalizzata
        let notification = NSUserNotification()
        notification.title = "🏠 La Casetta delle Petunie"
        notification.informativeText = "Nuova prenotazione: \(booking.guestName)"
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Data Models

struct BookingReservation: Identifiable {
    let id = UUID()
    let bookingId: String
    let guestName: String
    let email: String
    let phone: String
    let checkIn: Date
    let checkOut: Date
    let guests: Int
    let totalPrice: Double
    let source: String
    let status: BookingStatus
    let specialRequests: String?
    
    var nights: Int {
        Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 0
    }
}

enum BookingStatus: String, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .green
        case .cancelled: return .red
        }
    }
}

struct SyncLog: Identifiable {
    let id = UUID()
    let message: String
    let timestamp: Date
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let bookingApproved = Notification.Name("bookingApproved")
}
