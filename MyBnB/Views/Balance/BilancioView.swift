import SwiftUI

struct BilancioView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @StateObject private var bilancioService: BilancioService
    
    @State private var showingAddMovimento = false
    @State private var selectedMovimento: MovimentoFinanziario?
    @State private var movimentoToEdit: MovimentoFinanziario?
    
    init(viewModel: GestionaleViewModel) {
        self.viewModel = viewModel
        self._bilancioService = StateObject(wrappedValue: BilancioService(viewModel: viewModel))
    }
    
    var body: some View {
        VStack {
            // Header con titolo e bottone
            HStack {
                Text("Gestione Bilancio")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Nuovo Movimento") {
                    showingAddMovimento = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Header con statistiche rapide
            if let firstRiepilogo = bilancioService.riepiloghiMensili.first {
                BilancioStatsHeader(riepilogo: firstRiepilogo)
            }
            
            Divider()
            
            // Lista movimenti
            List {
                ForEach(bilancioService.movimenti) { movimento in
                    MovimentoRowSimple(
                        movimento: movimento,
                        onDetail: { selectedMovimento = movimento },
                        onEdit: { movimentoToEdit = movimento },
                        onDelete: {
                            Task {
                                await bilancioService.deleteMovimento(movimento)
                            }
                        }
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
        .sheet(isPresented: $showingAddMovimento) {
            AddMovimentoSimpleView(bilancioService: bilancioService)
        }
        // FIX: Rimossa NavigationView aggiuntiva e impostata dimensione corretta
        .sheet(item: $selectedMovimento) { movimento in
            MovimentoDetailView(movimento: movimento)
        }
        .sheet(item: $movimentoToEdit) { movimento in
            EditMovimentoView(movimento: movimento, bilancioService: bilancioService)
        }
        .task {
            await bilancioService.loadData()
        }
    }
}

// MARK: - Stats Header
struct BilancioStatsHeader: View {
    let riepilogo: RiepilogoMensile
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                title: "Entrate",
                value: "€\(Int(riepilogo.totaleEntrate))",
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            StatItem(
                title: "Uscite",
                value: "€\(Int(riepilogo.totaleUscite))",
                color: .red,
                icon: "arrow.down.circle.fill"
            )
            
            StatItem(
                title: "Saldo",
                value: "€\(Int(riepilogo.saldoMensile))",
                color: riepilogo.saldoMensile >= 0 ? .blue : .orange,
                icon: riepilogo.saldoMensile >= 0 ? "plus.circle.fill" : "minus.circle.fill"
            )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Movimento Row Simple
struct MovimentoRowSimple: View {
    let movimento: MovimentoFinanziario
    let onDetail: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: movimento.categoria.icona)
                .font(.title2)
                .foregroundColor(movimento.categoria.colore)
                .frame(width: 30)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(movimento.descrizione)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(movimento.categoria.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDate(movimento.data))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and actions
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(movimento.tipo == .entrata ? "+" : "-")€\(String(format: "%.2f", movimento.importo))")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(movimento.tipo.colore)
                
                HStack(spacing: 8) {
                    Button("Info", action: onDetail)
                        .font(.caption)
                    
                    Button("Modifica", action: onEdit)
                        .font(.caption)
                    
                    Button("Elimina") { showingDeleteAlert = true }
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Elimina Movimento", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive, action: onDelete)
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Sei sicuro di voler eliminare questo movimento?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Add Movimento Simple
struct AddMovimentoSimpleView: View {
    let bilancioService: BilancioService
    @Environment(\.dismiss) private var dismiss
    
    @State private var descrizione = ""
    @State private var importo = ""
    @State private var data = Date()
    @State private var tipo: MovimentoFinanziario.TipoMovimento = .entrata
    @State private var categoria: MovimentoFinanziario.CategoriaMovimento = .prenotazioni
    @State private var metodoPagamento: MovimentoFinanziario.MetodoPagamento = .contanti
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Base") {
                    TextField("Descrizione", text: $descrizione)
                    
                    HStack {
                        Text("€")
                        TextField("0.00", text: $importo)
                    }
                    
                    DatePicker("Data", selection: $data, displayedComponents: .date)
                }
                
                Section("Tipo e Categoria") {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(MovimentoFinanziario.TipoMovimento.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    
                    Picker("Categoria", selection: $categoria) {
                        ForEach(MovimentoFinanziario.CategoriaMovimento.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    
                    Picker("Metodo Pagamento", selection: $metodoPagamento) {
                        ForEach(MovimentoFinanziario.MetodoPagamento.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                }
                
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Nuovo Movimento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        Task { await saveMovimento() }
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private var isFormValid: Bool {
        !descrizione.isEmpty && !importo.isEmpty && Double(importo) != nil
    }
    
    private func saveMovimento() async {
        guard let amount = Double(importo) else { return }
        
        let movimento = MovimentoFinanziario(
            descrizione: descrizione,
            importo: amount,
            data: data,
            tipo: tipo,
            categoria: categoria,
            metodoPagamento: metodoPagamento,
            note: note
        )
        
        await bilancioService.addMovimento(movimento)
        dismiss()
    }
}


