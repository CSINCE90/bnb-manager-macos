//
//  AggiungiSpesaView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct AggiungiSpesaView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var descrizione = ""
    @State private var importoString = ""
    @State private var data = Date()
    @State private var categoria: Spesa.CategoriaSpesa = .altro
    @State private var strutturaId: UUID? = UUID(uuidString: UserDefaults.standard.string(forKey: "activeStrutturaId") ?? "")
    @StateObject private var strutturaRepo = StrutturaRepository()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Dettagli Spesa") {
                    TextField("Descrizione", text: $descrizione)
                    
                    HStack {
                        Text("€")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $importoString)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                    
                    DatePicker("Data", selection: $data, displayedComponents: .date)
                    
                    Picker("Categoria", selection: $categoria) {
                        ForEach(Spesa.CategoriaSpesa.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if !strutturaRepo.strutture.isEmpty {
                        Picker("Struttura", selection: Binding(get: { strutturaId }, set: { strutturaId = $0 })) {
                            ForEach(strutturaRepo.strutture, id: \.objectID) { s in
                                Text(s.nome ?? "Senza nome").tag(s.id as UUID?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nuova Spesa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        salvaSpesa()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            strutturaRepo.load()
            if strutturaId == nil, let first = strutturaRepo.strutture.first?.id { strutturaId = first }
        }
    }
    
    private var isFormValid: Bool {
        !descrizione.isEmpty &&
        !importoString.isEmpty &&
        Double(importoString) != nil
    }
    
    private func salvaSpesa() {
        guard let importo = Double(importoString) else { return }
        
        let nuovaSpesa = Spesa(
            strutturaId: strutturaId,
            descrizione: descrizione,
            importo: importo,
            data: data,
            categoria: categoria
        )
        
        viewModel.aggiungiSpesa(nuovaSpesa)
        dismiss()
    }
}

#Preview {
    AggiungiSpesaView(viewModel: GestionaleViewModel())
}
