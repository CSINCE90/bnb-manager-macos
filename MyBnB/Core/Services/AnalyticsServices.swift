//
//  AnalyticsServices.swift
//  MyBnB
//
//  Created by Francesco Chifari on 28/08/25.
//
import Foundation
import SwiftUI

@MainActor
class AnalyticsService: ObservableObject {
    @Published var metrics: BusinessMetrics?
    @Published var isLoading = false
    
    private let prenotazioneRepo: PrenotazioneRepository
    private let spesaRepo: SpesaRepository
    
    init(prenotazioneRepo: PrenotazioneRepository? = nil,
         spesaRepo: SpesaRepository? = nil) {
        self.prenotazioneRepo = prenotazioneRepo ?? PrenotazioneRepository()
        self.spesaRepo = spesaRepo ?? SpesaRepository()
    }
    
    func calculateMetrics(for period: AnalysisPeriod = .currentMonth) async {
        isLoading = true
        
        do {
            let prenotazioni = try await prenotazioneRepo.getAll()
            let spese = try await spesaRepo.getAll()
            
            let dateRange = period.dateRange
            
            // Filtra per periodo
            let filteredBookings = prenotazioni.filter { booking in
                booking.dataCheckIn >= dateRange.start && booking.dataCheckIn <= dateRange.end
            }
            
            let filteredExpenses = spese.filter { expense in
                expense.data >= dateRange.start && expense.data <= dateRange.end
            }
            
            metrics = BusinessMetrics(
                period: period,
                revenue: calculateRevenue(filteredBookings),
                expenses: calculateExpenses(filteredExpenses),
                occupancyRate: calculateOccupancyRate(filteredBookings, in: dateRange),
                averageStayLength: calculateAverageStayLength(filteredBookings),
                revenuePerNight: calculateRevenuePerNight(filteredBookings),
                topExpenseCategories: groupExpensesByCategory(filteredExpenses),
                monthlyTrend: calculateMonthlyTrend(prenotazioni),
                forecastedRevenue: forecastRevenue(basedOn: prenotazioni)
            )
        } catch {
            print("Error calculating metrics: \(error)")
        }
        
        isLoading = false
    }
    
    private func calculateRevenue(_ bookings: [Prenotazione]) -> Double {
        bookings
            .filter { $0.statoPrenotazione == .confermata || $0.statoPrenotazione == .completata }
            .reduce(0) { $0 + $1.prezzoTotale }
    }
    
    private func calculateExpenses(_ expenses: [Spesa]) -> Double {
        expenses.reduce(0) { $0 + $1.importo }
    }
    
    private func calculateOccupancyRate(_ bookings: [Prenotazione], in range: DateRange) -> Double {
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 1
        
        var occupiedDays = 0
        for booking in bookings {
            let bookingDays = calendar.dateComponents([.day],
                from: max(booking.dataCheckIn, range.start),
                to: min(booking.dataCheckOut, range.end)
            ).day ?? 0
            occupiedDays += bookingDays
        }
        
        return totalDays > 0 ? Double(occupiedDays) / Double(totalDays) * 100 : 0
    }
    
    private func calculateAverageStayLength(_ bookings: [Prenotazione]) -> Double {
        guard !bookings.isEmpty else { return 0 }
        let totalNights = bookings.reduce(0) { $0 + $1.numeroNotti }
        return Double(totalNights) / Double(bookings.count)
    }
    
    private func calculateRevenuePerNight(_ bookings: [Prenotazione]) -> Double {
        let totalRevenue = bookings.reduce(0) { $0 + $1.prezzoTotale }
        let totalNights = bookings.reduce(0) { $0 + $1.numeroNotti }
        
        return totalNights > 0 ? totalRevenue / Double(totalNights) : 0
    }
    
    private func groupExpensesByCategory(_ expenses: [Spesa]) -> [Spesa.CategoriaSpesa: Double] {
        Dictionary(grouping: expenses, by: { $0.categoria })
            .mapValues { $0.reduce(0) { $0 + $1.importo } }
    }
    
    private func calculateMonthlyTrend(_ bookings: [Prenotazione]) -> [MonthlyData] {
        let grouped = Dictionary(grouping: bookings) { booking in
            Calendar.current.dateComponents([.year, .month], from: booking.dataCheckIn)
        }
        
        return grouped.compactMap { components, bookings in
            guard let date = Calendar.current.date(from: components) else { return nil }
            let revenue = calculateRevenue(bookings)
            return MonthlyData(month: date, revenue: revenue, bookingCount: bookings.count)
        }.sorted { $0.month < $1.month }
    }
    
    private func forecastRevenue(basedOn historicalBookings: [Prenotazione]) -> Double {
        guard !historicalBookings.isEmpty else { return 0 }
        
        let lastThreeMonths = historicalBookings.filter {
            $0.dataCheckIn >= Date().addingTimeInterval(-90 * 24 * 3600)
        }
        
        let avgMonthlyRevenue = lastThreeMonths.reduce(0) { $0 + $1.prezzoTotale } / 3
        let growthFactor = 1.05
        
        return avgMonthlyRevenue * growthFactor
    }
}

// MARK: - Data Models
struct BusinessMetrics {
    let period: AnalysisPeriod
    let revenue: Double
    let expenses: Double
    let occupancyRate: Double
    let averageStayLength: Double
    let revenuePerNight: Double
    let topExpenseCategories: [Spesa.CategoriaSpesa: Double]
    let monthlyTrend: [MonthlyData]
    let forecastedRevenue: Double
    
    var profit: Double { revenue - expenses }
    var profitMargin: Double { revenue > 0 ? (profit / revenue) * 100 : 0 }
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: Date
    let revenue: Double
    let bookingCount: Int
}

enum AnalysisPeriod {
    case currentMonth
    case lastMonth
    case currentYear
    case custom(DateRange)
    
    var dateRange: DateRange {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .currentMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return DateRange(start: start, end: end)
            
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let start = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? now
            let end = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? now
            return DateRange(start: start, end: end)
            
        case .currentYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let end = calendar.dateInterval(of: .year, for: now)?.end ?? now
            return DateRange(start: start, end: end)
            
        case .custom(let range):
            return range
        }
    }
}

struct DateRange {
    let start: Date
    let end: Date
}
