//
//  PrenotazioniView.swift - Versione migliorata e responsive
//  MyBnB
//
//  Sostituisce il file esistente con layout adattivo e funzionalità migliorate
//

import SwiftUI
import CoreData

struct PrenotazioniView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @State private var mostraAggiungiPrenotazione = false
    @State private var searchText = ""
    @State private var selectedStatus: Prenotazione.StatoPrenotazione? = nil
    @State private var sortOrder = SortOrder.checkInDate
    @State private var showingDeleteAlert = false
    @State private var prenotazioneToDelete: Prenotazione?
    
    enum SortOrder: String, CaseIterable {
        case checkInDate = "Data Check-in"
        case amount = "Importo"
        case guestName = "Nome Ospite"
        case status = "Stato"
    }
    
    // Aggiorna automaticamente lo stato delle prenotazioni in base alla data attuale
    var prenotazioniAggiornate: [Prenotazione] {
        let oggi = Date()
        return viewModel.prenotazioni.map { prenotazione in
            var aggiornata = prenotazione
            if aggiornata.dataCheckOut < oggi && aggiornata.statoPrenotazione == .confermata {
                aggiornata.statoPrenotazione = .completata
            }
            return aggiornata
        }
    }

    // Prenotazioni filtrate e ordinate
    var prenotazioniFiltrate: [Prenotazione] {
        let filtered = prenotazioniAggiornate.filter { prenotazione in
            let matchesSearch = searchText.isEmpty ||
                prenotazione.nomeOspite.localizedCaseInsensitiveContains(searchText) ||
                prenotazione.email.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || prenotazione.statoPrenotazione == selectedStatus
            return matchesSearch && matchesStatus
        }

        switch sortOrder {
        case .checkInDate:
            return filtered.sorted { $0.dataCheckIn < $1.dataCheckIn }
        case .amount:
            return filtered.sorted { $0.prezzoTotale > $1.prezzoTotale }
        case .guestName:
            return filtered.sorted { $0.nomeOspite < $1.nomeOspite }
        case .status:
            return filtered.sorted { $0.statoPrenotazione.rawValue < $1.statoPrenotazione.rawValue }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                VStack(spacing: 0) {
                    // Header con statistiche
                    HeaderStatsView(viewModel: viewModel, geometry: geometry)
                    
                    // Barra filtri e ricerca
                    PrenotazioniFilterBarView(
                        searchText: $searchText,
                        selectedStatus: $selectedStatus,
                        sortOrder: $sortOrder,
                        geometry: geometry
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Lista prenotazioni
                    if prenotazioniFiltrate.isEmpty {
                        EmptyBookingsState(geometry: geometry)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: adaptiveSpacing(geometry)) {
                                ForEach(prenotazioniFiltrate) { prenotazione in
                                    if geometry.size.width > 700 {
                                        // Card estesa per schermi larghi
                                        EnhancedPrenotazioneCard(
                                            prenotazione: prenotazione,
                                            geometry: geometry,
                                            onDelete: {
                                                prenotazioneToDelete = prenotazione
                                                showingDeleteAlert = true
                                            }
                                        )
                                    } else {
                                        // Card compatta per schermi piccoli
                                        CompactPrenotazioneCard(
                                            prenotazione: prenotazione,
                                            geometry: geometry,
                                            onDelete: {
                                                prenotazioneToDelete = prenotazione
                                                showingDeleteAlert = true
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, adaptivePadding(geometry))
                            .padding(.bottom, 20)
                        }
                    }
                }
                .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
                .navigationTitle("Prenotazioni")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            mostraAggiungiPrenotazione = true
                        }) {
                            Label("Nuova", systemImage: "plus.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $mostraAggiungiPrenotazione) {
                    AggiungiPrenotazioneView(viewModel: viewModel)
                        .frame(minWidth: 600, minHeight: 500)
                }
                .alert("Conferma Eliminazione", isPresented: $showingDeleteAlert) {
                    Button("Annulla", role: .cancel) { }
                    Button("Elimina", role: .destructive) {
                        if let prenotazione = prenotazioneToDelete,
                           let index = viewModel.prenotazioni.firstIndex(where: { $0.id == prenotazione.id }) {
                            withAnimation {
                                viewModel.eliminaPrenotazione(at: IndexSet(integer: index))
                            }
                        }
                    }
                } message: {
                    Text("Sei sicuro di voler eliminare questa prenotazione?")
                }
            }
        }
    }
    
    // MARK: - Adaptive Helpers
    private func adaptiveSpacing(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 600 ? 12 : 16
    }
    
    private func adaptivePadding(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 600 ? 16 : 20
    }
}

// MARK: - Header Stats View
struct HeaderStatsView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing) {
            StatItemView(
                title: "Totale",
                value: "\(viewModel.prenotazioni.count)",
                icon: "calendar",
                color: .blue,
                geometry: geometry
            )
            
            StatItemView(
                title: "Attive",
                value: "\(viewModel.prenotazioniAttive.count)",
                icon: "clock.fill",
                color: .green,
                geometry: geometry
            )
            
            StatItemView(
                title: "Entrate",
                value: "€\(Int(viewModel.entrateTotali))",
                icon: "eurosign.circle.fill",
                color: .orange,
                geometry: geometry
            )
            
            if geometry.size.width > 600 {
                StatItemView(
                    title: "Media",
                    value: viewModel.prenotazioni.isEmpty ? "€0" : "€\(Int(viewModel.entrateTotali / Double(viewModel.prenotazioni.count)))",
                    icon: "chart.bar.fill",
                    color: .purple,
                    geometry: geometry
                )
            }
        }
        .padding(.horizontal, adaptivePadding)
        .padding(.vertical, adaptiveVerticalPadding)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    private var adaptiveSpacing: CGFloat {
        geometry.size.width < 600 ? 8 : 16
    }
    
    private var adaptivePadding: CGFloat {
        geometry.size.width < 600 ? 16 : 20
    }
    
    private var adaptiveVerticalPadding: CGFloat {
        geometry.size.width < 600 ? 12 : 16
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(adaptiveIconFont)
                .foregroundColor(color)
            
            Text(value)
                .font(adaptiveValueFont)
                .fontWeight(.bold)
            
            Text(title)
                .font(adaptiveTitleFont)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private var adaptiveIconFont: Font {
        geometry.size.width < 600 ? .callout : .title3
    }
    
    private var adaptiveValueFont: Font {
        geometry.size.width < 600 ? .callout : .headline
    }
    
    private var adaptiveTitleFont: Font {
        geometry.size.width < 600 ? .caption2 : .caption
    }
}

// MARK: - Filter Bar View
struct PrenotazioniFilterBarView: View {
    @Binding var searchText: String
    @Binding var selectedStatus: Prenotazione.StatoPrenotazione?
    @Binding var sortOrder: PrenotazioniView.SortOrder
    let geometry: GeometryProxy
    
    var body: some View {
        if geometry.size.width > 600 {
            // Layout orizzontale per schermi larghi
            HStack(spacing: 12) {
                searchField
                statusFilter
                sortPicker
            }
        } else {
            // Layout verticale per schermi piccoli
            VStack(spacing: 8) {
                searchField
                HStack(spacing: 12) {
                    statusFilter
                    sortPicker
                }
            }
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Cerca prenotazione...", text: $searchText)
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
    }
    
    private var statusFilter: some View {
        Menu {
            Button("Tutti") { selectedStatus = nil }
            Divider()
            ForEach(Prenotazione.StatoPrenotazione.allCases, id: \.self) { status in
                Button(status.rawValue) { selectedStatus = status }
            }
        } label: {
            HStack {
                Image(systemName: "tag.fill")
                Text(selectedStatus?.rawValue ?? "Stato")
                Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedStatus != nil ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var sortPicker: some View {
        Picker("Ordina", selection: $sortOrder) {
            ForEach(PrenotazioniView.SortOrder.allCases, id: \.self) { order in
                Text(geometry.size.width < 600 ? order.rawValue.prefix(10) + "..." : order.rawValue).tag(order)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Enhanced Prenotazione Card (per schermi larghi)
struct EnhancedPrenotazioneCard: View {
    let prenotazione: Prenotazione
    let geometry: GeometryProxy
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showingDetails = false
    @EnvironmentObject var viewModel: GestionaleViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(prenotazione.statoPrenotazione.colore)
                .frame(width: 4)

            // Guest info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(prenotazione.nomeOspite)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(prenotazione.statoPrenotazione.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(prenotazione.statoPrenotazione.colore.opacity(0.2))
                        .foregroundColor(prenotazione.statoPrenotazione.colore)
                        .cornerRadius(6)
                }

                HStack {
                    Label(prenotazione.email, systemImage: "envelope")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Label("\(prenotazione.numeroOspiti) ospiti", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Date info
            VStack(alignment: .center, spacing: 4) {
                Text(formatDate(prenotazione.dataCheckIn))
                    .font(.callout)
                    .fontWeight(.medium)
                Text("→")
                    .foregroundColor(.secondary)
                Text(formatDate(prenotazione.dataCheckOut))
                    .font(.callout)
                    .fontWeight(.medium)
                Text("\(prenotazione.numeroNotti) notti")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100)

            // Price and actions
            VStack(alignment: .trailing, spacing: 8) {
                Text(String(format: "€%.0f", prenotazione.prezzoTotale))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

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

                        // Cambia stato button/menu
                        Menu {
                            ForEach(Prenotazione.StatoPrenotazione.allCases, id: \.self) { stato in
                                Button(stato.rawValue) {
                                    if let index = viewModel.prenotazioni.firstIndex(where: { $0.id == prenotazione.id }) {
                                        viewModel.prenotazioni[index].statoPrenotazione = stato
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 80)
        }
        .padding()
        .background(cardBackground)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .sheet(isPresented: $showingDetails) {
            PrenotazioneDetailPopover(prenotazione: prenotazione)
                .frame(minWidth: 600, minHeight: 500)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(NSColor.controlBackgroundColor))
            .shadow(color: isHovered ? .black.opacity(0.1) : .black.opacity(0.05),
                   radius: isHovered ? 8 : 4,
                   y: isHovered ? 4 : 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Prenotazione Card (per schermi piccoli)
struct CompactPrenotazioneCard: View {
    let prenotazione: Prenotazione
    let geometry: GeometryProxy
    let onDelete: () -> Void

    @State private var showingActions = false
    @EnvironmentObject var viewModel: GestionaleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(prenotazione.statoPrenotazione.colore)
                    .frame(width: 8, height: 8)

                Text(prenotazione.nomeOspite)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Button(action: { showingActions.toggle() }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(prenotazione.email)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("\(formatDate(prenotazione.dataCheckIn)) → \(formatDate(prenotazione.dataCheckOut))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(prenotazione.numeroOspiti) ospiti • \(prenotazione.numeroNotti) notti")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(prenotazione.statoPrenotazione.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(prenotazione.statoPrenotazione.colore.opacity(0.2))
                        .foregroundColor(prenotazione.statoPrenotazione.colore)
                        .cornerRadius(4)

                    Spacer()

                    Text(String(format: "€%.0f", prenotazione.prezzoTotale))
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .contextMenu {
            Button("Elimina", role: .destructive, action: onDelete)
            Menu("Cambia stato") {
                ForEach(Prenotazione.StatoPrenotazione.allCases, id: \.self) { stato in
                    Button(stato.rawValue) {
                        if let index = viewModel.prenotazioni.firstIndex(where: { $0.id == prenotazione.id }) {
                            viewModel.prenotazioni[index].statoPrenotazione = stato
                        }
                    }
                }
            }
        }
        .confirmationDialog("Azioni per \(prenotazione.nomeOspite)", isPresented: $showingActions, titleVisibility: .visible) {
            Button("Elimina", role: .destructive, action: onDelete)
            Button("Annulla", role: .cancel) { }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

// MARK: - Prenotazione Detail Popover
struct PrenotazioneDetailPopover: View {
    let prenotazione: Prenotazione
    @Environment(\.dismiss) private var dismiss
    @State private var movimenti: [MovimentoFinanziario] = []
    private let context = CoreDataManager.shared.viewContext
    @State private var showingAddMovimento = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
            }
            Text("Dettagli Prenotazione")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRowView(label: "Ospite", value: prenotazione.nomeOspite)
                DetailRowView(label: "Email", value: prenotazione.email)
                if !prenotazione.telefono.isEmpty {
                    DetailRowView(label: "Telefono", value: prenotazione.telefono)
                }
                DetailRowView(label: "Check-in", value: formatFullDate(prenotazione.dataCheckIn))
                DetailRowView(label: "Check-out", value: formatFullDate(prenotazione.dataCheckOut))
                DetailRowView(label: "Ospiti", value: "\(prenotazione.numeroOspiti)")
                DetailRowView(label: "Totale", value: String(format: "€%.2f", prenotazione.prezzoTotale))
                
                if !prenotazione.note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prenotazione.note)
                            .font(.caption)
                    }
                }

                if !movimenti.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text("Movimenti Collegati (\(movimenti.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(movimenti) { m in
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: m.tipo == .entrata ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(m.tipo == .entrata ? .green : .red)
                            Text(m.descrizione)
                                .font(.caption)
                            Spacer()
                            Text(String(format: "€%.2f", m.importo))
                                .font(.caption2)
                                .foregroundColor(m.tipo == .entrata ? .green : .red)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Aggiungi Movimento") {
                        NotificationCenter.default.post(
                            name: Notification.Name("NavigateToBilancioWithFilter"),
                            object: nil,
                            userInfo: [
                                "prenotazioneId": prenotazione.id,
                                "openAddMovement": true
                            ]
                        )
                        dismiss()
                    }
                    Button("Apri in Bilancio") {
                        NotificationCenter.default.post(
                            name: Notification.Name("NavigateToBilancioWithFilter"),
                            object: nil,
                            userInfo: ["prenotazioneId": prenotazione.id]
                        )
                        dismiss()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear { loadMovimentiCollegati() }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }

    private func loadMovimentiCollegati() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDMovimentoFinanziario")
        request.sortDescriptors = [NSSortDescriptor(key: "data", ascending: false)]
        request.fetchBatchSize = 100
        request.predicate = NSPredicate(format: "prenotazione.id == %@ OR prenotazioneId == %@", prenotazione.id as CVarArg, prenotazione.id as CVarArg)
        do {
            let items = try context.fetch(request)
            self.movimenti = items.compactMap { cd in
                guard let descrizione = cd.value(forKey: "descrizione") as? String,
                      let importo = cd.value(forKey: "importo") as? Double,
                      let data = cd.value(forKey: "data") as? Date,
                      let tipoRaw = cd.value(forKey: "tipo") as? String,
                      let categoriaRaw = cd.value(forKey: "categoria") as? String,
                      let metodoPagamentoRaw = cd.value(forKey: "metodoPagamento") as? String
                else { return nil }
                let id = cd.value(forKey: "id") as? UUID ?? UUID()
                let note = cd.value(forKey: "note") as? String ?? ""
                let prenId = cd.value(forKey: "prenotazioneId") as? UUID
                let updatedAt = cd.value(forKey: "updatedAt") as? Date ?? Date()
                let createdAt = cd.value(forKey: "createdAt") as? Date ?? Date()
                guard let tipo = MovimentoFinanziario.TipoMovimento(rawValue: tipoRaw),
                      let categoria = MovimentoFinanziario.CategoriaMovimento(rawValue: categoriaRaw),
                      let metodoPagamento = MovimentoFinanziario.MetodoPagamento(rawValue: metodoPagamentoRaw)
                else { return nil }
                return MovimentoFinanziario(
                    id: id,
                    descrizione: descrizione,
                    importo: importo,
                    data: data,
                    tipo: tipo,
                    categoria: categoria,
                    metodoPagamento: metodoPagamento,
                    note: note,
                    prenotazioneId: prenId,
                    updatedAt: updatedAt,
                    createdAt: createdAt
                )
            }
        } catch {
            print("❌ Errore caricamento movimenti collegati: \(error)")
        }
    }
}

// MARK: - Detail Row View
struct DetailRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

// MARK: - Empty Bookings State
struct EmptyBookingsState: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: adaptiveIconSize))
                .foregroundColor(.secondary)
            
            Text("Nessuna prenotazione trovata")
                .font(adaptiveTitleFont)
                .fontWeight(.medium)
            
            if geometry.size.width > 400 {
                Text("Prova a modificare i filtri o aggiungi una nuova prenotazione")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(50)
    }
    
    private var adaptiveIconSize: CGFloat {
        geometry.size.width < 400 ? 40 : 60
    }
    
    private var adaptiveTitleFont: Font {
        geometry.size.width < 400 ? .callout : .title3
    }
}

#Preview {
    PrenotazioniView(viewModel: GestionaleViewModel())
}
