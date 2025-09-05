//
//  EnhancedCalendarioView.swift - Versione corretta degli errori
//  MyBnB
//
//  Risolve tutti gli errori di compilazione
//

import SwiftUI

struct EnhancedCalendarioView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var selectedDate = Date()
    @State private var calendarView: CalendarViewType = .month
    @State private var showingAddBooking = false
    
    enum CalendarViewType: String, CaseIterable {
        case month = "Mese"
        case week = "Settimana"
        case list = "Lista"
    }
    
    // Prenotazioni per la data selezionata
    var prenotazioniDelGiorno: [Prenotazione] {
        viewModel.prenotazioni.filter { prenotazione in
            let calendar = Calendar.current
            return calendar.isDate(prenotazione.dataCheckIn, inSameDayAs: selectedDate) ||
                   calendar.isDate(prenotazione.dataCheckOut, inSameDayAs: selectedDate) ||
                   (prenotazione.dataCheckIn <= selectedDate && prenotazione.dataCheckOut >= selectedDate)
        }
    }
    
    // Prenotazioni del mese corrente
    var prenotazioniDelMese: [Prenotazione] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        
        return viewModel.prenotazioni.filter { prenotazione in
            let checkInComponents = calendar.dateComponents([.year, .month], from: prenotazione.dataCheckIn)
            let checkOutComponents = calendar.dateComponents([.year, .month], from: prenotazione.dataCheckOut)
            
            return (checkInComponents.year == components.year && checkInComponents.month == components.month) ||
                   (checkOutComponents.year == components.year && checkOutComponents.month == components.month)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con titolo
            HStack {
                Text("Calendario Prenotazioni")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Nuova Prenotazione") {
                    showingAddBooking = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            HSplitView {
                // Pannello sinistro - Calendario
                VStack(spacing: 0) {
                    // Header con controlli
                    CalendarHeaderView(
                        selectedDate: $selectedDate,
                        calendarView: $calendarView
                    )
                    
                    Divider()
                    
                    // Vista calendario
                    switch calendarView {
                    case .month:
                        MonthCalendarView(
                            selectedDate: $selectedDate,
                            prenotazioni: viewModel.prenotazioni
                        )
                    case .week:
                        WeekCalendarView(
                            selectedDate: $selectedDate,
                            prenotazioni: viewModel.prenotazioni
                        )
                    case .list:
                        BookingListView(
                            prenotazioni: prenotazioniDelMese
                        )
                    }
                    
                    Spacer()
                }
                .frame(minWidth: 400)
                
                // Pannello destro - Dettagli giorno
                VStack(spacing: 0) {
                    // Header dettagli
                    DayDetailsHeader(
                        date: selectedDate,
                        bookingCount: prenotazioniDelGiorno.count
                    )
                    
                    Divider()
                    
                    // Lista prenotazioni del giorno
                    if prenotazioniDelGiorno.isEmpty {
                        EmptyDayView(date: selectedDate)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(prenotazioniDelGiorno) { prenotazione in
                                    BookingEventCard(
                                        prenotazione: prenotazione,
                                        selectedDate: selectedDate
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                }
                .frame(minWidth: 350)
            }
        }
        .sheet(isPresented: $showingAddBooking) {
            AggiungiPrenotazioneView(viewModel: viewModel)
        }
    }
}

// MARK: - Calendar Header View
struct CalendarHeaderView: View {
    @Binding var selectedDate: Date
    @Binding var calendarView: EnhancedCalendarioView.CalendarViewType
    
    var body: some View {
        HStack {
            // Navigazione mese
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .frame(minWidth: 150)
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Today button
            Button("Oggi") {
                withAnimation {
                    selectedDate = Date()
                }
            }
            
            // View selector
            Picker("Vista", selection: $calendarView) {
                ForEach(EnhancedCalendarioView.CalendarViewType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
        }
        .padding()
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    private func previousMonth() {
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
    }
    
    private func nextMonth() {
        withAnimation {
            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
    }
}

// MARK: - Month Calendar View
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let prenotazioni: [Prenotazione]
    
    let daysOfWeek = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"]
    
    var monthDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? Date()
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let numberOfDays = range.count
        
        let firstWeekday = (calendar.component(.weekday, from: startOfMonth) + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header giorni settimana
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Griglia giorni
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            bookings: bookingsForDate(date),
                            onTap: {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 80)
                    }
                }
            }
            .padding()
        }
    }
    
    private func bookingsForDate(_ date: Date) -> [Prenotazione] {
        prenotazioni.filter { prenotazione in
            let calendar = Calendar.current
            return calendar.isDate(prenotazione.dataCheckIn, inSameDayAs: date) ||
                   calendar.isDate(prenotazione.dataCheckOut, inSameDayAs: date) ||
                   (prenotazione.dataCheckIn <= date && prenotazione.dataCheckOut >= date)
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let bookings: [Prenotazione]
    let onTap: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.callout)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .white : .primary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isToday ? Color.blue : Color.clear)
                    )
                
                // Indicatori prenotazioni
                if !bookings.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(bookings.prefix(3)) { booking in
                            Circle()
                                .fill(booking.statoPrenotazione.colore)
                                .frame(width: 6, height: 6)
                        }
                        if bookings.count > 3 {
                            Text("+\(bookings.count - 3)")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Week Calendar View
struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    let prenotazioni: [Prenotazione]
    
    var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? Date()
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 0) {
                        // Header giorno
                        VStack(spacing: 4) {
                            Text(dayName(day))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(dayNumber(day))
                                .font(.title3)
                                .fontWeight(Calendar.current.isDateInToday(day) ? .bold : .regular)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Calendar.current.isDate(day, inSameDayAs: selectedDate) ?
                            Color.blue.opacity(0.2) : Color(NSColor.controlBackgroundColor)
                        )
                        
                        Divider()
                        
                        // Eventi del giorno
                        VStack(spacing: 4) {
                            ForEach(bookingsForDate(day)) { booking in
                                MiniBookingCard(booking: booking, date: day)
                            }
                        }
                        .padding(4)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        withAnimation {
                            selectedDate = day
                        }
                    }
                    
                    if day != weekDays.last {
                        Divider()
                    }
                }
            }
        }
    }
    
    private func dayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func bookingsForDate(_ date: Date) -> [Prenotazione] {
        prenotazioni.filter { prenotazione in
            let calendar = Calendar.current
            return calendar.isDate(prenotazione.dataCheckIn, inSameDayAs: date) ||
                   calendar.isDate(prenotazione.dataCheckOut, inSameDayAs: date) ||
                   (prenotazione.dataCheckIn <= date && prenotazione.dataCheckOut >= date)
        }
    }
}

// MARK: - Mini Booking Card
struct MiniBookingCard: View {
    let booking: Prenotazione
    let date: Date
    
    private var eventType: String {
        let calendar = Calendar.current
        if calendar.isDate(booking.dataCheckIn, inSameDayAs: date) {
            return "Check-in"
        } else if calendar.isDate(booking.dataCheckOut, inSameDayAs: date) {
            return "Check-out"
        } else {
            return "Soggiorno"
        }
    }
    
    private var eventIcon: String {
        switch eventType {
        case "Check-in": return "arrow.right.circle.fill"
        case "Check-out": return "arrow.left.circle.fill"
        default: return "bed.double.fill"
        }
    }
    
    private var eventColor: Color {
        switch eventType {
        case "Check-in": return .green
        case "Check-out": return .orange
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: eventIcon)
                    .font(.caption2)
                    .foregroundColor(eventColor)
                Text(eventType)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            
            Text(booking.nomeOspite)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(eventColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(eventColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Booking List View
struct BookingListView: View {
    let prenotazioni: [Prenotazione]
    
    var sortedBookings: [Prenotazione] {
        prenotazioni.sorted { $0.dataCheckIn < $1.dataCheckIn }
    }
    
    var body: some View {
        ScrollView {
            if sortedBookings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nessuna prenotazione questo mese")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(50)
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedBookings) { booking in
                        BookingListCard(booking: booking)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Booking List Card
struct BookingListCard: View {
    let booking: Prenotazione
    
    var body: some View {
        HStack(spacing: 16) {
            // Date range
            VStack(alignment: .center, spacing: 4) {
                Text(dayNumber(booking.dataCheckIn))
                    .font(.title2)
                    .fontWeight(.bold)
                Text(monthName(booking.dataCheckIn))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(dayNumber(booking.dataCheckOut))
                    .font(.title2)
                    .fontWeight(.bold)
                Text(monthName(booking.dataCheckOut))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            Divider()
            
            // Booking info
            VStack(alignment: .leading, spacing: 8) {
                Text(booking.nomeOspite)
                    .font(.headline)
                
                HStack {
                    Label("\(booking.numeroOspiti) ospiti", systemImage: "person.2")
                    Label("\(booking.numeroNotti) notti", systemImage: "moon.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status and price
            VStack(alignment: .trailing, spacing: 8) {
                Text(booking.statoPrenotazione.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(booking.statoPrenotazione.colore.opacity(0.2))
                    .foregroundColor(booking.statoPrenotazione.colore)
                    .cornerRadius(6)
                
                Text(String(format: "€%.0f", booking.prezzoTotale))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }
    
    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func monthName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Day Details Header
struct DayDetailsHeader: View {
    let date: Date
    let bookingCount: Int
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateString)
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                if bookingCount > 0 {
                    Label("\(bookingCount) prenotazion\(bookingCount == 1 ? "e" : "i")",
                          systemImage: "calendar.badge.plus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Label("Nessuna prenotazione", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if Calendar.current.isDateInToday(date) {
                    Text("OGGI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Booking Event Card
struct BookingEventCard: View {
    let prenotazione: Prenotazione
    let selectedDate: Date
    
    private var eventType: EventType {
        let calendar = Calendar.current
        if calendar.isDate(prenotazione.dataCheckIn, inSameDayAs: selectedDate) {
            return .checkIn
        } else if calendar.isDate(prenotazione.dataCheckOut, inSameDayAs: selectedDate) {
            return .checkOut
        } else {
            return .staying
        }
    }
    
    enum EventType {
        case checkIn, checkOut, staying
        
        var title: String {
            switch self {
            case .checkIn: return "Check-in"
            case .checkOut: return "Check-out"
            case .staying: return "In soggiorno"
            }
        }
        
        var icon: String {
            switch self {
            case .checkIn: return "arrow.right.circle.fill"
            case .checkOut: return "arrow.left.circle.fill"
            case .staying: return "bed.double.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .checkIn: return .green
            case .checkOut: return .orange
            case .staying: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: eventType.icon)
                    .font(.title2)
                    .foregroundColor(eventType.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(eventType.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prenotazione.nomeOspite)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(prenotazione.statoPrenotazione.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(prenotazione.statoPrenotazione.colore.opacity(0.2))
                    .foregroundColor(prenotazione.statoPrenotazione.colore)
                    .cornerRadius(6)
            }
            
            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(prenotazione.email, systemImage: "envelope")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if !prenotazione.telefono.isEmpty {
                    Label(prenotazione.telefono, systemImage: "phone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(prenotazione.numeroOspiti) ospiti", systemImage: "person.2")
                    Spacer()
                    Label("\(prenotazione.numeroNotti) notti", systemImage: "moon.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Text("Totale:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "€%.2f", prenotazione.prezzoTotale))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            if !prenotazione.note.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Note:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prenotazione.note)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(eventType.color.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Empty Day View
struct EmptyDayView: View {
    let date: Date
    
    private var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Nessuna prenotazione")
                .font(.title3)
                .fontWeight(.medium)
            
            Text(isWeekend ? "Giornata libera nel weekend" : "Giornata libera")
                .font(.callout)
                .foregroundColor(.secondary)
            
            if isWeekend {
                Text("I weekend sono periodi di alta richiesta")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(50)
    }
}

#Preview {
    EnhancedCalendarioView(viewModel: GestionaleViewModel())
}
