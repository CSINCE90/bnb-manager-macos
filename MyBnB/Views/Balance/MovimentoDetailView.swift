//
//  MovimentoDetailView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 02/09/25.
//

import SwiftUI

struct MovimentoDetailView: View {
    let movimento: MovimentoFinanziario
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: movimento.categoria.icona)
                            .font(.largeTitle)
                            .foregroundColor(movimento.categoria.colore)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(movimento.descrizione)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(movimento.categoria.rawValue)
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(movimento.tipo == .entrata ? "+" : "-")€\(String(format: "%.2f", movimento.importo))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(movimento.tipo.colore)
                    }
                    
                    Divider()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailSection(title: "Informazioni Principali") {
                            DetailRow(label: "Tipo", value: movimento.tipo.rawValue)
                            DetailRow(label: "Categoria", value: movimento.categoria.rawValue)
                            DetailRow(label: "Importo", value: "€\(String(format: "%.2f", movimento.importo))")
                            DetailRow(label: "Metodo Pagamento", value: movimento.metodoPagamento.rawValue)
                        }
                        
                        DetailSection(title: "Date") {
                            DetailRow(label: "Data Movimento", value: formatDate(movimento.data))
                            DetailRow(label: "Creato il", value: formatDate(movimento.createdAt))
                            if movimento.updatedAt != movimento.createdAt {
                                DetailRow(label: "Ultima modifica", value: formatDate(movimento.updatedAt))
                            }
                        }
                        
                        if !movimento.note.isEmpty {
                            DetailSection(title: "Note") {
                                Text(movimento.note)
                                    .font(.callout)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                        
                        if let prenotazioneId = movimento.prenotazioneId {
                            DetailSection(title: "Prenotazione Collegata") {
                                DetailRow(label: "ID Prenotazione", value: prenotazioneId.uuidString, copyable: true)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dettagli Movimento")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

// MARK: - Detail Section Helper
struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
}

// MARK: - Detail Row Helper
struct DetailRow: View {
    let label: String
    let value: String
    var copyable: Bool = false
    
    @State private var showingCopied = false
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .textSelection(.enabled)
            
            Spacer()
            
            if copyable {
                Button(action: copyToClipboard) {
                    Image(systemName: showingCopied ? "checkmark" : "doc.on.doc")
                        .foregroundColor(showingCopied ? .green : .blue)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        
        withAnimation {
            showingCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopied = false
            }
        }
    }
}

