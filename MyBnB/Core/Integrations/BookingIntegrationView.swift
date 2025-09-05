// ===== FILE 3: Views/Integrations/BookingIntegrationView.swift =====

import SwiftUI

struct BookingIntegrationView: View {
    @StateObject private var bookingService = BookingIntegrationService()
    @ObservedObject var viewModel: GestionaleViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Connection Status
                ConnectionStatusCard(service: bookingService)
                
                // Pending Bookings
                if !bookingService.pendingBookings.isEmpty {
                    PendingBookingsSection(
                        bookings: bookingService.pendingBookings,
                        onApprove: bookingService.approveBooking,
                        onReject: bookingService.rejectBooking
                    )
                }
                
                // Booking Controls
                BookingControlsSection(service: bookingService)
                
                // Sync Logs
                SyncLogsSection(logs: bookingService.syncLogs)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("🏨 Booking.com Integration")
        }
        .onReceive(NotificationCenter.default.publisher(for: .bookingApproved)) { notification in
            if let booking = notification.object as? Prenotazione {
                viewModel.aggiungiPrenotazione(booking)
            }
        }
    }
}

struct ConnectionStatusCard: View {
    @ObservedObject var service: BookingIntegrationService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: service.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(service.isConnected ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text("Booking.com Integration")
                        .font(.headline)
                    Text(service.connectionStatus)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !service.isConnected {
                    Button("Connect") {
                        Task {
                            await service.connectToBooking()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            if service.isConnected, let lastSync = service.lastSync {
                HStack {
                    Text("Last sync:")
                        .foregroundColor(.secondary)
                    Text(lastSync.formatted(date: .omitted, time: .shortened))
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("🌐 View on Booking.com") {
                        if let url = URL(string: "https://www.booking.com/hotel/it/la-casetta-delle-petunie.it.html") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    
                    Text("🔗 Webhook: Active")
                        .font(.caption)
                        .foregroundColor(.green)
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

struct PendingBookingsSection: View {
    let bookings: [BookingReservation]
    let onApprove: (BookingReservation) -> Void
    let onReject: (BookingReservation, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📥 Pending Bookings (\(bookings.count))")
                .font(.headline)
            
            ForEach(bookings) { booking in
                PendingBookingCard(
                    booking: booking,
                    onApprove: { onApprove(booking) },
                    onReject: { onReject(booking, "Declined by host") }
                )
            }
        }
    }
}

struct PendingBookingCard: View {
    let booking: BookingReservation
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(booking.guestName)
                        .font(.headline)
                    Text("Booking ID: \(booking.bookingId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "€%.2f", booking.totalPrice))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            // Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(booking.email, systemImage: "envelope")
                        .font(.caption)
                    if !booking.phone.isEmpty {
                        Label(booking.phone, systemImage: "phone")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(booking.checkIn.formatted(date: .abbreviated, time: .omitted))")
                    Text("→ \(booking.checkOut.formatted(date: .abbreviated, time: .omitted))")
                    Text("\(booking.nights) nights, \(booking.guests) guests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Special Requests
            if let requests = booking.specialRequests, !requests.isEmpty {
                Text("💬 \(requests)")
                    .font(.caption)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Actions
            HStack {
                Button("❌ Decline") {
                    onReject()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("✅ Approve & Add") {
                    onApprove()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct BookingControlsSection: View {
    @ObservedObject var service: BookingIntegrationService
    
    var body: some View {
        HStack {
            if service.isConnected {
                Button("🔄 Manual Sync") {
                    Task {
                        await service.manualSync()
                    }
                }
                
                Button("❌ Disconnect") {
                    service.disconnect()
                }
                .foregroundColor(.red)
            }
            
            Spacer()
        }
    }
}

struct SyncLogsSection: View {
    let logs: [SyncLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📋 Sync Logs")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logs.prefix(10)) { log in
                        HStack {
                            Text(log.formattedTime)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text(log.message)
                                .font(.caption)
                            
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxHeight: 150)
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

#Preview {
    BookingIntegrationView(viewModel: GestionaleViewModel())
}
