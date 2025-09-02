//
//  PriceOptimizerModel.swift
//  MyBnB
//
//  Created by Francesco Chifari on 01/09/25.
//

// ===== FILE 2: Core/ML/PriceOptimizationModel.swift =====

import CoreML

// Wrapper per il modello CoreML generato
class PriceOptimizationModel {
    private let model: MLModel
    
    init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }
    
    func prediction(input: PriceOptimizationModelInput) throws -> PriceOptimizationModelOutput {
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            "month": MLFeatureValue(double: input.month),
            "dayOfWeek": MLFeatureValue(double: input.dayOfWeek),
            "guests": MLFeatureValue(double: input.guests),
            "stayLength": MLFeatureValue(double: input.stayLength),
            "leadTime": MLFeatureValue(double: input.leadTime),
            "isWeekend": MLFeatureValue(double: input.isWeekend),
            "isSummer": MLFeatureValue(double: input.isSummer),
            "isHoliday": MLFeatureValue(double: input.isHoliday)
        ])
        
        let prediction = try model.prediction(from: provider)
        let price = prediction.featureValue(for: "price")?.doubleValue ?? 50.0
        
        return PriceOptimizationModelOutput(price: price)
    }
}

struct PriceOptimizationModelInput {
    let month: Double
    let dayOfWeek: Double
    let guests: Double
    let stayLength: Double
    let leadTime: Double
    let isWeekend: Double
    let isSummer: Double
    let isHoliday: Double
}

struct PriceOptimizationModelOutput {
    let price: Double
}


