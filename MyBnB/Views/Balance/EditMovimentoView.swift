//
//  EditMovimentoView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 02/09/25.
//

import SwiftUI

struct EditMovimentoView: View {
    let movimento: MovimentoFinanziario
    let bilancioService: BilancioService
    @Environment(\.dismiss) private var dismiss
    
    @State private var descrizione: String
    @State private var importo: String
    @State private var data: Date
    @State private var tipo: MovimentoFinanziario.TipoMovimento
    @State private var categoria: MovimentoFinanziario.CategoriaMovimento
    @State private var metodoPagamento: MovimentoFinanziario.MetodoPagamento
    @State private var note: String
    
    init(movimento: MovimentoFinanziario, bilancioService: BilancioService) {
        self.movimento = movimento
        self.bilancioService = bilancioService
        
        _descrizione = State(initialValue: movimento.descrizione)
        _importo = State(initialValue: String(movimento.importo))
        _data = State(initialValue: movimento.data)
        _tipo = State(initialValue: movimento.tipo)
        _categoria = State(initialValue: movimento.categoria)
        _metodoPagamento = State(initialValue: movimento.metodoPagamento)
        _note = State(initialValue: movimento.note)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Base") {
                    TextField("Descrizione", text: $descrizione)
                    
                    HStack {
                        Text("€")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $importo)
                    }
                    
                    DatePicker("Data", selection: $data, displayedComponents: .date)
                }
                
                Section("Classificazione") {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(MovimentoFinanziario.TipoMovimento.allCases, id: \.self) { tipoItem in
                            Label(tipoItem.rawValue, systemImage: tipoItem.icona)
                                .tag(tipoItem)
                        }
                    }
                    
                    Picker("Categoria", selection: $categoria) {
                        ForEach(MovimentoFinanziario.CategoriaMovimento.allCases, id: \.self) { cat in
                            if (tipo == .entrata && cat.isEntrata) || (tipo == .uscita && !cat.isEntrata) {
                                Label(cat.rawValue, systemImage: cat.icona)
                                    .tag(cat)
                            }
                        }
                    }
                    
                    Picker("Metodo Pagamento", selection: $metodoPagamento) {
                        ForEach(MovimentoFinanziario.MetodoPagamento.allCases, id: \.self) { metodo in
                            Label(metodo.rawValue, systemImage: metodo.icona)
                                .tag(metodo)
                        }
                    }
                }
                
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Modifica Movimento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        Task {
                            await saveMovimento()
                        }
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
        
        var updatedMovimento = movimento
        updatedMovimento.descrizione = descrizione
        updatedMovimento.importo = amount
        updatedMovimento.data = data
        updatedMovimento.tipo = tipo
        updatedMovimento.categoria = categoria
        updatedMovimento.metodoPagamento = metodoPagamento
        updatedMovimento.note = note
        
        await bilancioService.updateMovimento(updatedMovimento)
        dismiss()
    }
}
