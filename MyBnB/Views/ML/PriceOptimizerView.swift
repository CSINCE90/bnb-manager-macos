import SwiftUI

struct PriceOptimizerView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @StateObject private var optimizer = PriceOptimizer()
    
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedGuests = 2
    @State private var selectedStayLength = 3
    @State private var currentSuggestion: PriceSuggestion?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con titolo
            HStack {
                Text("🤖 ML Price Optimizer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !optimizer.isTraining && optimizer.model == nil && !viewModel.prenotazioni.isEmpty {
                    Button("🎓 Train Model") {
                        Task {
                            await trainModelSafely()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Status Header
                    StatusHeaderView(optimizer: optimizer, isLoading: isLoading)
                    
                    // Input Controls
                    if optimizer.model != nil && !optimizer.isTraining {
                        PriceControlsSection(
                            selectedMonth: $selectedMonth,
                            selectedGuests: $selectedGuests,
                            selectedStayLength: $selectedStayLength,
                            onSuggest: suggestPrice,
                            isLoading: isLoading
                        )
                    }
                    
                    // Results
                    if let suggestion = currentSuggestion {
                        SuggestionCard(suggestion: suggestion)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    // Empty state
                    if viewModel.prenotazioni.isEmpty {
                        EmptyStateView()
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Non fare training automatico - troppo pesante
        }
    }
    
    @MainActor
    private func trainModelSafely() async {
        isLoading = true
        
        // Aggiungi un delay per evitare il blocco dell'UI
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 secondi
        
        await optimizer.trainModel(with: viewModel.prenotazioni)
        isLoading = false
    }
    
    private func suggestPrice() {
        guard !isLoading else { return }
        
        Task {
            isLoading = true
            
            let today = Date()
            let dayOfWeek = Calendar.current.component(.weekday, from: today)
            
            let suggestion = await optimizer.suggestPrice(
                month: selectedMonth,
                dayOfWeek: dayOfWeek,
                guests: selectedGuests,
                stayLength: selectedStayLength
            )
            
            await MainActor.run {
                withAnimation(.spring()) {
                    currentSuggestion = suggestion
                    isLoading = false
                }
            }
        }
    }
}

struct StatusHeaderView: View {
    @ObservedObject var optimizer: PriceOptimizer
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading) {
                    Text("AI Price Optimization")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if optimizer.isTraining || isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Processing...")
                                .foregroundColor(.orange)
                        }
                    } else if optimizer.model != nil {
                        Text("Accuracy: \(optimizer.accuracy, format: .percent)")
                            .foregroundColor(.green)
                    } else {
                        Text("Ready to train")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
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
    let isLoading: Bool
    
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
                    .disabled(isLoading)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Ospiti:")
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper("\(selectedGuests)", value: $selectedGuests, in: 1...4)
                        .frame(width: 150)
                        .disabled(isLoading)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Notti:")
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper("\(selectedStayLength)", value: $selectedStayLength, in: 1...14)
                        .frame(width: 150)
                        .disabled(isLoading)
                    
                    Spacer()
                }
            }
            
            Button(action: onSuggest) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "Calcolando..." : "💡 Suggerisci Prezzo")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(isLoading)
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

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Nessuna prenotazione disponibile")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("L'AI ha bisogno di dati storici per suggerire prezzi ottimali. Aggiungi alcune prenotazioni per iniziare.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(50)
    }
}

#Preview {
    PriceOptimizerView(viewModel: GestionaleViewModel())
}
