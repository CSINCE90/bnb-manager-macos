//
//  PriceOptimizerView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 01/09/25.
//

// ===== FILE 3: Views/ML/PriceOptimizerView.swift =====

import SwiftUI

struct PriceOptimizerView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @StateObject private var optimizer = PriceOptimizer()
    
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedGuests = 2
    @State private var selectedStayLength = 3
    @State private var currentSuggestion: PriceSuggestion?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HeaderView(optimizer: optimizer, viewModel: viewModel)
                
                // Input Controls
                PriceControlsSection(
                    selectedMonth: $selectedMonth,
                    selectedGuests: $selectedGuests,
                    selectedStayLength: $selectedStayLength,
                    onSuggest: suggestPrice
                )
                
                // Results
                if let suggestion = currentSuggestion {
                    SuggestionCard(suggestion: suggestion)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("🤖 ML Price Optimizer")
        }
        .onAppear {
            if optimizer.model == nil && !viewModel.prenotazioni.isEmpty {
                Task {
                    await optimizer.trainModel(with: viewModel.prenotazioni)
                }
            }
        }
    }
    
    private func suggestPrice() {
        Task {
            let today = Date()
            let dayOfWeek = Calendar.current.component(.weekday, from: today)
            
            let suggestion = await optimizer.suggestPrice(
                month: selectedMonth,
                dayOfWeek: dayOfWeek,
                guests: selectedGuests,
                stayLength: selectedStayLength
            )
            
            withAnimation(.spring()) {
                currentSuggestion = suggestion
            }
        }
    }
}

struct HeaderView: View {
    @ObservedObject var optimizer: PriceOptimizer
    @ObservedObject var viewModel: GestionaleViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading) {
                    Text("AI Price Optimization")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if optimizer.isTraining {
                        Text("Training model...")
                            .foregroundColor(.orange)
                    } else if optimizer.model != nil {
                        Text("Accuracy: \(optimizer.accuracy, format: .percent)")
                            .foregroundColor(.green)
                    } else {
                        Text("Ready to train")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !optimizer.isTraining && optimizer.model == nil {
                    Button("🎓 Train Model") {
                        Task {
                            await optimizer.trainModel(with: viewModel.prenotazioni)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            if optimizer.isTraining {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct PriceControlsSection: View {
    @Binding var selectedMonth: Int
    @Binding var selectedGuests: Int
    @Binding var selectedStayLength: Int
    let onSuggest: () -> Void
    
    private let monthNames = Calendar.current.monthSymbols
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parametri Prenotazione")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Mese:")
                        .frame(width: 100, alignment: .leading)
                    
                    Picker("Mese", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthNames[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Ospiti:")
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper("\(selectedGuests)", value: $selectedGuests, in: 1...8)
                        .frame(width: 150)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Notti:")
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper("\(selectedStayLength)", value: $selectedStayLength, in: 1...14)
                        .frame(width: 150)
                    
                    Spacer()
                }
            }
            
            Button("💡 Suggerisci Prezzo") {
                onSuggest()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct SuggestionCard: View {
    let suggestion: PriceSuggestion
    
    var body: some View {
        VStack(spacing: 16) {
            // Price Display
            HStack {
                VStack(alignment: .leading) {
                    Text("Prezzo Suggerito")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(suggestion.formattedPrice)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Confidenza")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(suggestion.confidencePercentage)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            // Range and Demand
            HStack {
                VStack(alignment: .leading) {
                    Text("Range Consigliato")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(suggestion.formattedRange)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Domanda")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(suggestion.demandLevel.color)
                            .frame(width: 8, height: 8)
                        Text(suggestion.demandLevel.rawValue)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Divider()
            
            // Reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("Analisi AI")
                    .font(.headline)
                
                Text(suggestion.reasoning)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    PriceOptimizerView(viewModel: GestionaleViewModel())
}
