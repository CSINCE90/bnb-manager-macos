//
//  EnachedSpeseView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 30/08/25.
//

import SwiftUI
import Charts

struct EnhancedSpeseView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var mostraAggiungiSpesa = false
    @State private var selectedCategory: Spesa.CategoriaSpesa? = nil
    @State private var searchText = ""
    @State private var sortOrder = SortOrder.date
    @State private var showingDeleteAlert = false
    @State private var spesaToDelete: Spesa?
    
    enum SortOrder: String, CaseIterable {
        case date = "Data"
        case amount = "Importo"
        case category = "Categoria"
    }
    
    // Calcoli
    var speseFiltrate: [Spesa] {
        let filtered = viewModel.spese.filter { spesa in
            let matchesSearch = searchText.isEmpty ||
                spesa.descrizione.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || spesa.categoria == selectedCategory
            return matchesSearch && matchesCategory
        }
        
        switch sortOrder {
        case .date:
            return filtered.sorted { $0.data > $1.data }
        case .amount:
            return filtered.sorted { $0.importo > $1.importo }
        case .category:
            return filtered.sorted { $0.categoria.rawValue < $1.categoria.rawValue }
        }
    }
    
    var spesePerCategoria: [(categoria: Spesa.CategoriaSpesa, totale: Double)] {
        Dictionary(grouping: viewModel.spese, by: { $0.categoria })
            .map { (categoria: $0.key, totale: $0.value.reduce(0) { $0 + $1.importo }) }
            .sorted { $0.totale > $1.totale }
    }
    
    var totaleSpeseFiltrate: Double {
        speseFiltrate.reduce(0) { $0 + $1.importo }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header con statistiche
                HeaderSpeseView(
                    totaleSpese: viewModel.speseTotali,
                    numeroSpese: viewModel.spese.count,
                    mediaSpese: viewModel.spese.isEmpty ? 0 : viewModel.speseTotali / Double(viewModel.spese.count)
                )
                
                // Grafico distribuzione categorie
                if !viewModel.spese.isEmpty {
                    CategoryChartView(spesePerCategoria: spesePerCategoria)
                        .frame(height: 200)
                        .padding()
                }
                
                // Barra filtri e ricerca
                FilterBarView(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    sortOrder: $sortOrder
                )
                .padding(.horizontal)
                
                // Lista spese
                ScrollView {
                    if speseFiltrate.isEmpty {
                        EmptySpesaState()
                            .padding(.top, 50)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(speseFiltrate) { spesa in
                                SpesaCardView(
                                    spesa: spesa,
                                    onDelete: {
                                        spesaToDelete = spesa
                                        showingDeleteAlert = true
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                            }
                        }
                        .padding()
                    }
                }
                
                // Footer con totale filtrato
                if !speseFiltrate.isEmpty && (searchText != "" || selectedCategory != nil) {
                    HStack {
                        Text("Totale filtrato:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("€\(String(format: "%.2f", totaleSpeseFiltrate))")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                }
            }
            .navigationTitle("Gestione Spese")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { mostraAggiungiSpesa = true }) {
                        Label("Aggiungi", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $mostraAggiungiSpesa) {
                AggiungiSpesaView(viewModel: viewModel)
            }
            .alert("Conferma Eliminazione", isPresented: $showingDeleteAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Elimina", role: .destructive) {
                    if let spesa = spesaToDelete,
                       let index = viewModel.spese.firstIndex(where: { $0.id == spesa.id }) {
                        withAnimation {
                            viewModel.eliminaSpesa(at: IndexSet(integer: index))
                        }
                    }
                }
            } message: {
                Text("Sei sicuro di voler eliminare questa spesa?")
            }
        }
    }
}

// MARK: - Header Spese View
struct HeaderSpeseView: View {
    let totaleSpese: Double
    let numeroSpese: Int
    let mediaSpese: Double
    
    var body: some View {
        HStack(spacing: 20) {
            StatCardCompact(
                title: "Totale Spese",
                value: String(format: "€%.2f", totaleSpese),
                icon: "creditcard.fill",
                color: .red
            )
            
            StatCardCompact(
                title: "Numero Spese",
                value: "\(numeroSpese)",
                icon: "number.circle.fill",
                color: .blue
            )
            
            StatCardCompact(
                title: "Media",
                value: String(format: "€%.2f", mediaSpese),
                icon: "chart.bar.fill",
                color: .orange
            )
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Stat Card Compact
struct StatCardCompact: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Category Chart View
struct CategoryChartView: View {
    let spesePerCategoria: [(categoria: Spesa.CategoriaSpesa, totale: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribuzione per Categoria")
                .font(.headline)
            
            Chart(spesePerCategoria, id: \.categoria) { item in
                SectorMark(
                    angle: .value("Totale", item.totale),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Categoria", item.categoria.rawValue))
                .cornerRadius(4)
            }
            
            // Legenda orizzontale
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(spesePerCategoria, id: \.categoria) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForCategory(item.categoria))
                                .frame(width: 10, height: 10)
                            Text(item.categoria.rawValue)
                                .font(.caption)
                            Text("€\(Int(item.totale))")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func colorForCategory(_ category: Spesa.CategoriaSpesa) -> Color {
        switch category {
        case .pulizie: return .blue
        case .manutenzione: return .orange
        case .utenze: return .green
        case .tasse: return .red
        case .altro: return .purple
        }
    }
}

// MARK: - Filter Bar View
struct FilterBarView: View {
    @Binding var searchText: String
    @Binding var selectedCategory: Spesa.CategoriaSpesa?
    @Binding var sortOrder: EnhancedSpeseView.SortOrder
    
    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Cerca spesa...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Category filter
            Menu {
                Button("Tutte") {
                    selectedCategory = nil
                }
                Divider()
                ForEach(Spesa.CategoriaSpesa.allCases, id: \.self) { categoria in
                    Button(categoria.rawValue) {
                        selectedCategory = categoria
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                    Text(selectedCategory?.rawValue ?? "Categoria")
                    Image(systemName: "chevron.down")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedCategory != nil ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Sort order
            Picker("Ordina", selection: $sortOrder) {
                ForEach(EnhancedSpeseView.SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
        }
    }
}

// MARK: - Spesa Card View
struct SpesaCardView: View {
    let spesa: Spesa
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Categoria indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(colorForCategory(spesa.categoria))
                .frame(width: 4)
            
            // Icon
            Image(systemName: iconForCategory(spesa.categoria))
                .font(.title2)
                .foregroundColor(colorForCategory(spesa.categoria))
                .frame(width: 40)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(spesa.descrizione)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Label(spesa.categoria.rawValue, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Label(formatDate(spesa.data), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Importo e azioni
            VStack(alignment: .trailing, spacing: 8) {
                Text(String(format: "€%.2f", spesa.importo))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                if isHovered {
                    HStack(spacing: 8) {
                        Button(action: { showingDetails = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: isHovered ? .black.opacity(0.1) : .black.opacity(0.05),
                       radius: isHovered ? 8 : 4,
                       y: isHovered ? 4 : 2)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .popover(isPresented: $showingDetails) {
            SpesaDetailView(spesa: spesa)
                .frame(width: 300, height: 200)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func colorForCategory(_ category: Spesa.CategoriaSpesa) -> Color {
        switch category {
        case .pulizie: return .blue
        case .manutenzione: return .orange
        case .utenze: return .green
        case .tasse: return .red
        case .altro: return .purple
        }
    }
    
    private func iconForCategory(_ category: Spesa.CategoriaSpesa) -> String {
        switch category {
        case .pulizie: return "sparkles"
        case .manutenzione: return "wrench.and.screwdriver"
        case .utenze: return "bolt.fill"
        case .tasse: return "doc.text.fill"
        case .altro: return "ellipsis.circle"
        }
    }
}

// MARK: - Spesa Detail View
struct SpesaDetailView: View {
    let spesa: Spesa
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dettagli Spesa")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Label(spesa.descrizione, systemImage: "text.quote")
                Label(spesa.categoria.rawValue, systemImage: "tag")
                Label(formatDate(spesa.data), systemImage: "calendar")
                Label(String(format: "€%.2f", spesa.importo), systemImage: "eurosign")
                    .fontWeight(.bold)
            }
            .font(.callout)
            
            Spacer()
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

// MARK: - Empty Spesa State
struct EmptySpesaState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Nessuna spesa registrata")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Aggiungi la tua prima spesa per iniziare a tracciare le uscite")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 300)
    }
}
