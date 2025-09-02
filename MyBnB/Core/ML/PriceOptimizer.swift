// ===== FILE 1: Core/ML/PriceOptimizer.swift =====

import Foundation
import CreateML
import CoreML
import SwiftUI

@MainActor
class PriceOptimizer: ObservableObject {
    @Published var isTraining = false
    @Published var suggestions: [PriceSuggestion] = []
    @Published var model: PriceOptimizationModel?
    @Published var accuracy: Double = 0.0
    
    private let modelName = "PriceOptimizationModel"
    
    init() {
            Task {
                await loadExistingModel()
            }
        }
    
    // MARK: - Public Methods
    
    func trainModel(with bookings: [Prenotazione]) async {
        guard !bookings.isEmpty else { return }
        
        isTraining = true
        
        do {
            // Prepara i dati di training
            let trainingData = prepareTrainingData(bookings)
            
            // Crea il modello con CreateML
            let mlModel = try await createMLModel(from: trainingData)
            
            // Salva il modello
            let modelURL = getModelURL()
            let metadata = MLModelMetadata(
                author: "Francesco Chifari",
                shortDescription: "Modello per ottimizzazione prezzi MyBnB",
                license: "MIT",
                version: "1.0"
                
            )
            
            try mlModel.write(to: modelURL, metadata: metadata)
            
            // Compila e carica il nuovo modello
            let compiledURL = try await MLModel.compileModel(at: modelURL)
            self.model = try PriceOptimizationModel(contentsOf: compiledURL)
            
            // Calcola accuracy
            self.accuracy = await calculateModelAccuracy(trainingData)
            
            print("✅ ML Model trained successfully with accuracy: \(accuracy)")
            
        } catch {
            print("❌ ML Training failed: \(error)")
        }
        
        isTraining = false
    }
    
    func suggestPrice(
        month: Int,
        dayOfWeek: Int,
        guests: Int,
        stayLength: Int,
        leadTime: Int = 30
    ) async -> PriceSuggestion? {
        
        guard let model = model else {
            return fallbackPriceSuggestion(guests: guests, stayLength: stayLength)
        }
        
        do {
            // Prepara input per il modello
            let input = PriceOptimizationModelInput(
                month: Double(month),
                dayOfWeek: Double(dayOfWeek),
                guests: Double(guests),
                stayLength: Double(stayLength),
                leadTime: Double(leadTime),
                isWeekend: dayOfWeek >= 6 ? 1.0 : 0.0,
                isSummer: (month >= 6 && month <= 8) ? 1.0 : 0.0,
                isHoliday: isHolidayPeriod(month: month) ? 1.0 : 0.0
            )
            
            // Predizione
            let output = try model.prediction(input: input)
            let predictedPrice = output.price
            
            // Calcola range di confidenza
            let confidence = calculateConfidence(
                month: month,
                dayOfWeek: dayOfWeek,
                guests: guests
            )
            
            let suggestion = PriceSuggestion(
                suggestedPrice: predictedPrice,
                confidence: confidence,
                priceRange: (
                    min: predictedPrice * 0.85,
                    max: predictedPrice * 1.15
                ),
                reasoning: generateReasoning(
                    month: month,
                    dayOfWeek: dayOfWeek,
                    guests: guests,
                    price: predictedPrice
                ),
                demandLevel: calculateDemandLevel(month: month, dayOfWeek: dayOfWeek)
            )
            
            return suggestion
            
        } catch {
            print("❌ ML Prediction failed: \(error)")
            return fallbackPriceSuggestion(guests: guests, stayLength: stayLength)
        }
    }
    
    func generatePricingCalendar(
        for months: Int = 3,
        with bookings: [Prenotazione]
    ) async -> [CalendarPricing] {
        
        var calendar: [CalendarPricing] = []
        let startDate = Calendar.current.startOfDay(for: Date())
        
        for dayOffset in 0..<(months * 30) {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            let month = Calendar.current.component(.month, from: date)
            let dayOfWeek = Calendar.current.component(.weekday, from: date)
            
            // Check if date is already booked
            let isBooked = bookings.contains { booking in
                date >= booking.dataCheckIn && date < booking.dataCheckOut
            }
            
            if !isBooked {
                // Suggest pricing for different guest counts
                var pricingOptions: [PriceSuggestion] = []
                
                for guestCount in [1, 2, 3, 4] {
                    if let suggestion = await suggestPrice(
                        month: month,
                        dayOfWeek: dayOfWeek,
                        guests: guestCount,
                        stayLength: 2
                    ) {
                        pricingOptions.append(suggestion)
                    }
                }
                
                calendar.append(CalendarPricing(
                    date: date,
                    isBooked: false,
                    pricingOptions: pricingOptions
                ))
            } else {
                calendar.append(CalendarPricing(
                    date: date,
                    isBooked: true,
                    pricingOptions: []
                ))
            }
        }
        
        return calendar
    }
    
    // MARK: - Private Methods
    
    private func loadExistingModel() async {
        let modelURL = getModelURL()
        
        if FileManager.default.fileExists(atPath: modelURL.path) {
            do {
                let compiledURL = try await MLModel.compileModel(at: modelURL)
                self.model = try PriceOptimizationModel(contentsOf: compiledURL)
                print("✅ Existing ML model loaded")
            } catch {
                print("⚠️ Failed to load existing model: \(error)")
            }
        }
    }
    
    private func prepareTrainingData(_ bookings: [Prenotazione]) -> [(input: MLFeatures, output: Double)] {
        return bookings.compactMap { booking in
            let calendar = Calendar.current
            let month = calendar.component(.month, from: booking.dataCheckIn)
            let dayOfWeek = calendar.component(.weekday, from: booking.dataCheckIn)
            let stayLength = booking.numeroNotti
            
            let features = MLFeatures(
                month: Double(month),
                dayOfWeek: Double(dayOfWeek),
                guests: Double(booking.numeroOspiti),
                stayLength: Double(stayLength),
                leadTime: 30.0, // Default lead time
                isWeekend: dayOfWeek >= 6 ? 1.0 : 0.0,
                isSummer: (month >= 6 && month <= 8) ? 1.0 : 0.0,
                isHoliday: isHolidayPeriod(month: month) ? 1.0 : 0.0
            )
            
            // Price per night
            let pricePerNight = booking.prezzoTotale / Double(max(stayLength, 1))
            
            return (input: features, output: pricePerNight)
        }
    }
    
    private func createMLModel(from trainingData: [(input: MLFeatures, output: Double)]) async throws -> MLLinearRegressor {
        // Converti in formato CreateML
        var dataTable: [String: [Double]] = [
            "month": [],
            "dayOfWeek": [],
            "guests": [],
            "stayLength": [],
            "leadTime": [],
            "isWeekend": [],
            "isSummer": [],
            "isHoliday": [],
            "price": []
        ]
        
        for (features, price) in trainingData {
            dataTable["month"]?.append(features.month)
            dataTable["dayOfWeek"]?.append(features.dayOfWeek)
            dataTable["guests"]?.append(features.guests)
            dataTable["stayLength"]?.append(features.stayLength)
            dataTable["leadTime"]?.append(features.leadTime)
            dataTable["isWeekend"]?.append(features.isWeekend)
            dataTable["isSummer"]?.append(features.isSummer)
            dataTable["isHoliday"]?.append(features.isHoliday)
            dataTable["price"]?.append(price)
        }
        
        let mlData = try MLDataTable(dictionary: dataTable)
        let regressor = try MLLinearRegressor(trainingData: mlData, targetColumn: "price")
        return regressor
    }
    
    private func calculateModelAccuracy(_ trainingData: [(input: MLFeatures, output: Double)]) async -> Double {
        guard let model = model else { return 0.0 }
        
        var totalError = 0.0
        var predictions = 0
        
        for (features, actualPrice) in trainingData.suffix(10) { // Test on last 10 samples
            do {
                let input = PriceOptimizationModelInput(
                    month: features.month,
                    dayOfWeek: features.dayOfWeek,
                    guests: features.guests,
                    stayLength: features.stayLength,
                    leadTime: features.leadTime,
                    isWeekend: features.isWeekend,
                    isSummer: features.isSummer,
                    isHoliday: features.isHoliday
                )
                
                let output = try model.prediction(input: input)
                let error = abs(output.price - actualPrice) / actualPrice
                totalError += error
                predictions += 1
            } catch {
                continue
            }
        }
        
        return predictions > 0 ? max(0, 1 - (totalError / Double(predictions))) : 0.0
    }
    
    private func calculateConfidence(month: Int, dayOfWeek: Int, guests: Int) -> Double {
        var confidence = 0.7 // Base confidence
        
        // Higher confidence for common patterns
        if guests >= 2 && guests <= 4 { confidence += 0.1 }
        if dayOfWeek >= 2 && dayOfWeek <= 5 { confidence += 0.1 } // Weekdays
        if month >= 4 && month <= 10 { confidence += 0.1 } // Tourist season
        
        return min(confidence, 0.95)
    }
    
    private func generateReasoning(month: Int, dayOfWeek: Int, guests: Int, price: Double) -> String {
        var reasons: [String] = []
        
        // Seasonal reasoning
        switch month {
        case 12, 1, 2:
            reasons.append("Stagione invernale - prezzi base")
        case 3, 4, 5:
            reasons.append("Primavera - domanda crescente")
        case 6, 7, 8:
            reasons.append("Alta stagione estiva - prezzi premium")
        case 9, 10, 11:
            reasons.append("Autunno - domanda moderata")
        default:
            break
        }
        
        // Day of week reasoning
        if dayOfWeek >= 6 {
            reasons.append("Weekend - maggiorazione +15%")
        } else {
            reasons.append("Giorni feriali - prezzi standard")
        }
        
        // Guest count reasoning
        switch guests {
        case 1:
            reasons.append("Singolo ospite - prezzo base")
        case 2:
            reasons.append("Coppia - fascia più richiesta")
        case 3, 4:
            reasons.append("Gruppo - prezzo per persona ottimizzato")
        default:
            reasons.append("Gruppo numeroso - prezzo speciale")
        }
        
        return reasons.joined(separator: " • ")
    }
    
    private func calculateDemandLevel(month: Int, dayOfWeek: Int) -> DemandLevel {
        let summerBoost = (month >= 6 && month <= 8) ? 1 : 0
        let weekendBoost = (dayOfWeek >= 6) ? 1 : 0
        let holidayBoost = isHolidayPeriod(month: month) ? 1 : 0
        
        let demandScore = summerBoost + weekendBoost + holidayBoost
        
        switch demandScore {
        case 0: return .low
        case 1: return .medium
        case 2: return .high
        default: return .veryHigh
        }
    }
    
    private func isHolidayPeriod(month: Int) -> Bool {
        // Italian holiday periods
        return month == 8 || month == 12 || month == 4 // August, December, Easter period
    }
    
    private func fallbackPriceSuggestion(guests: Int, stayLength: Int) -> PriceSuggestion {
        // Simple rule-based fallback
        let basePrice = 50.0 + Double(guests * 15)
        let stayDiscount = stayLength >= 7 ? 0.9 : 1.0
        let finalPrice = basePrice * stayDiscount
        
        return PriceSuggestion(
            suggestedPrice: finalPrice,
            confidence: 0.6,
            priceRange: (min: finalPrice * 0.8, max: finalPrice * 1.2),
            reasoning: "Calcolo basato su regole standard - Allena il modello ML per suggerimenti più accurati",
            demandLevel: .medium
        )
    }
    
    private func getModelURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("\(modelName).mlmodel")
    }
}

// MARK: - Data Models

struct MLFeatures {
    let month: Double
    let dayOfWeek: Double
    let guests: Double
    let stayLength: Double
    let leadTime: Double
    let isWeekend: Double
    let isSummer: Double
    let isHoliday: Double
}

struct PriceSuggestion: Identifiable {
    let id = UUID()
    let suggestedPrice: Double
    let confidence: Double
    let priceRange: (min: Double, max: Double)
    let reasoning: String
    let demandLevel: DemandLevel
    
    var formattedPrice: String {
        return String(format: "€%.0f", suggestedPrice)
    }
    
    var formattedRange: String {
        return String(format: "€%.0f - €%.0f", priceRange.min, priceRange.max)
    }
    
    var confidencePercentage: String {
        return String(format: "%.0f%%", confidence * 100)
    }
}

struct CalendarPricing: Identifiable {
    let id = UUID()
    let date: Date
    let isBooked: Bool
    let pricingOptions: [PriceSuggestion]
    
    var bestPrice: PriceSuggestion? {
        return pricingOptions.max(by: { $0.confidence < $1.confidence })
    }
}

enum DemandLevel: String, CaseIterable {
    case low = "Bassa"
    case medium = "Media"
    case high = "Alta"
    case veryHigh = "Molto Alta"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .veryHigh: return .red
        }
    }
    
    var multiplier: Double {
        switch self {
        case .low: return 0.85
        case .medium: return 1.0
        case .high: return 1.15
        case .veryHigh: return 1.3
        }
    }
}
