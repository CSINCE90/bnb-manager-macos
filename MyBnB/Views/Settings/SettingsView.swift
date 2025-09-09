import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GestionaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoBackup") private var autoBackup = true
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    @AppStorage("totalRooms") private var totalRooms = 20
    
    @State private var showingExportConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Generali
                Section("Impostazioni Generali") {
                    //Stepper("Numero Totale Camere: \(totalRooms)", value: $totalRooms, in: 1...20)
                    
                    Picker("Valuta", selection: $currencySymbol) {
                        Text("€ Euro").tag("€")
                    }
                    .pickerStyle(.segmented)
                }
                
                // Notifiche
                Section("Notifiche") {
                    Toggle("Abilita Notifiche", systemImage: "bell", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Riceverai notifiche per:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("• Check-in e Check-out")
                            Text("• Promemoria pulizie")
                            Text("• Scadenze pagamenti")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                // Aspetto
                Section("Aspetto") {
                    Toggle("Modalità Scura", systemImage: "moon", isOn: $darkModeEnabled)
                }
                
                // Backup e Dati
                Section("Backup e Dati") {
                    Toggle("Backup Automatico", systemImage: "icloud", isOn: $autoBackup)
                    
                    Button {
                        showingExportConfirmation = true
                    } label: {
                        Label("Esporta Tutti i Dati", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset Dati", systemImage: "trash")
                    }
                }
                
                // Database
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
                
                // Informazioni
                Section("Informazioni") {
                    Button("Logout") {
                        AuthService.shared.logout()
                    }
                    
                    Button {
                        showingAbout = true
                    } label: {
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
            .confirmationDialog("Esporta Dati", isPresented: $showingExportConfirmation) {
                Button("Esporta come JSON") { exportAsJSON() }
                Button("Esporta come CSV") { exportAsCSV() }
                Button("Annulla", role: .cancel) {}
            }
            .alert("Reset Dati", isPresented: $showingResetConfirmation) {
                Button("Elimina Tutto", role: .destructive) { resetAllData() }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("Questa azione eliminerà tutti i dati. Sei sicuro?")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private func calculateDatabaseSize() -> String {
        let prenotazioniSize = viewModel.prenotazioni.count * 500
        let speseSize = viewModel.spese.count * 200
        let totalBytes = prenotazioniSize + speseSize
        
        if totalBytes < 1024 {
            return "\(totalBytes) B"
        } else if totalBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(totalBytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(totalBytes) / (1024 * 1024))
        }
    }
    
    private func exportAsJSON() {
        if let data = DataExportService.shared.exportAllToJSON() {
            let formatter = ISO8601DateFormatter()
            let name = "MyBnB_Export_\(formatter.string(from: Date())).json".replacingOccurrences(of: ":", with: "-")
            let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
            do {
                try data.write(to: url)
                print("✅ Esportazione completata: \(url.path)")
            } catch {
                print("❌ Errore esportazione: \(error)")
            }
        }
    }
    private func exportAsCSV() { print("Export CSV") }
    
    private func resetAllData() {
        viewModel.prenotazioni.removeAll()
        viewModel.spese.removeAll()
        //viewModel.salvaDati()
    }
}
