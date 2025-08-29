//
//  SettingsView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 29/08/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoBackup") private var autoBackup = true
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    @AppStorage("totalRooms") private var totalRooms = 5
    
    @State private var showingExportConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Sezione Generali
                Section("Impostazioni Generali") {
                    HStack {
                        Label("Numero Totale Camere", systemImage: "bed.double")
                        Spacer()
                        Stepper("\(totalRooms)", value: $totalRooms, in: 1...20)
                    }
                    
                    HStack {
                        Label("Valuta", systemImage: "eurosign.circle")
                        Spacer()
                        Picker("", selection: $currencySymbol) {
                            Text("€ Euro").tag("€")
                            Text("$ Dollaro").tag("$")
                            Text("£ Sterlina").tag("£")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                }
                
                // Sezione Notifiche
                Section("Notifiche") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Abilita Notifiche", systemImage: "bell")
                    }
                    
                    if notificationsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Riceverai notifiche per:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Check-in e Check-out")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Promemoria pulizie")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Scadenze pagamenti")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Sezione Aspetto
                Section("Aspetto") {
                    Toggle(isOn: $darkModeEnabled) {
                        Label("Modalità Scura", systemImage: "moon")
                    }
                }
                
                // Sezione Backup e Dati
                Section("Backup e Dati") {
                    Toggle(isOn: $autoBackup) {
                        Label("Backup Automatico", systemImage: "icloud")
                    }
                    
                    Button(action: { exportData() }) {
                        Label("Esporta Tutti i Dati", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingResetConfirmation = true }) {
                        Label("Reset Dati", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // Sezione Statistiche Database
                Section("Database") {
                    HStack {
                        Label("Prenotazioni Salvate", systemImage: "calendar")
                        Spacer()
                        Text("\(viewModel.prenotazioni.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Spese Registrate", systemImage: "creditcard")
                        Spacer()
                        Text("\(viewModel.spese.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Spazio Utilizzato", systemImage: "internaldrive")
                        Spacer()
                        Text(calculateDatabaseSize())
                            .foregroundColor(.secondary)
                    }
                }
                
                // Sezione Info
                Section("Informazioni") {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Label("Info su MyBnB", systemImage: "info.circle")
                            Spacer()
                            Text("v2.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Impostazioni")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("Esporta Dati", isPresented: $showingExportConfirmation) {
            Button("Esporta come JSON") {
                exportAsJSON()
            }
            Button("Esporta come CSV") {
                exportAsCSV()
            }
            Button("Annulla", role: .cancel) {}
        }
        .alert("Reset Dati", isPresented: $showingResetConfirmation) {
            Button("Elimina Tutto", role: .destructive) {
                resetAllData()
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Questa azione eliminerà tutti i dati. Sei sicuro?")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func calculateDatabaseSize() -> String {
        // Calcolo approssimativo
        let prenotazioniSize = viewModel.prenotazioni.count * 500 // ~500 bytes per prenotazione
        let speseSize = viewModel.spese.count * 200 // ~200 bytes per spesa
        let totalBytes = prenotazioniSize + speseSize
        
        if totalBytes < 1024 {
            return "\(totalBytes) B"
        } else if totalBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(totalBytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024 * 1024))
        }
    }
    
    private func exportData() {
        showingExportConfirmation = true
    }
    
    private func exportAsJSON() {
        // Implementazione export JSON
        print("Exporting as JSON...")
    }
    
    private func exportAsCSV() {
        // Implementazione export CSV
        print("Exporting as CSV...")
    }
    
    private func resetAllData() {
        // Reset tutti i dati
        viewModel.prenotazioni.removeAll()
        viewModel.spese.removeAll()
        viewModel.salvaDati()
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("MyBnB")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Versione 2.0")
                .foregroundColor(.secondary)
            
            Text("Gestionale per Bed & Breakfast")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Sviluppato da Francesco Chifari")
                Text("© 2025")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Button("Chiudi") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}
