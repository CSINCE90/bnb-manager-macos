//
//  AggiungiPrenotazioneView.swift
//  MyBnB
//
//  Created by Francesco Chifari on 27/08/25.
//

import SwiftUI

struct AggiungiPrenotazioneView: View {
   @ObservedObject var viewModel: GestionaleViewModel
   @Environment(\.dismiss) private var dismiss
   
   @State private var nomeOspite = ""
   @State private var email = ""
   @State private var telefono = ""
   @State private var dataCheckIn = Date()
   @State private var dataCheckOut = Date().addingTimeInterval(86400) // +1 giorno
   @State private var numeroOspiti = 1
   @State private var prezzoTotale = ""
   @State private var note = ""
   
   var body: some View {
       NavigationStack {
           Form {
               Section("Informazioni Ospite") {
                   TextField("Nome Ospite", text: $nomeOspite)
                   TextField("Email", text: $email)
                       #if os(iOS)
                       .keyboardType(.emailAddress)
                       .textInputAutocapitalization(.never)
                       #endif
                   TextField("Telefono", text: $telefono)
                       #if os(iOS)
                       .keyboardType(.phonePad)
                       #endif
               }
               
               Section("Dettagli Soggiorno") {
                   DatePicker("Check-in", selection: $dataCheckIn, displayedComponents: .date)
                   DatePicker("Check-out", selection: $dataCheckOut, displayedComponents: .date)
                   
                   Stepper("Numero Ospiti: \(numeroOspiti)", value: $numeroOspiti, in: 1...10)
                   
                   TextField("Prezzo Totale", text: $prezzoTotale)
                       #if os(iOS)
                       .keyboardType(.decimalPad)
                       #endif
               }
               
               Section("Note") {
                   ZStack(alignment: .topLeading) {
                       if note.isEmpty {
                           Text("Note aggiuntive")
                               .foregroundColor(.secondary)
                               .padding(.all, 8)
                       }
                       TextEditor(text: $note)
                           .frame(minHeight: 60)
                   }
               }
           }
           .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
           .navigationTitle("Nuova Prenotazione")
           .toolbar {
               ToolbarItem(placement: .cancellationAction) {
                   Button("Annulla") {
                       dismiss()
                   }
               }
               
               ToolbarItem(placement: .confirmationAction) {
                   Button("Salva") {
                       salvaPrenotazione()
                   }
                   .disabled(!isFormValid)
               }
           }
       }
       .frame(minWidth: 600, minHeight: 500)
   }
   
   private var isFormValid: Bool {
       !nomeOspite.isEmpty &&
       !email.isEmpty &&
       !prezzoTotale.isEmpty &&
       dataCheckOut > dataCheckIn
   }
   
   private func salvaPrenotazione() {
       guard let prezzo = Double(prezzoTotale) else { return }
       
       let nuovaPrenotazione = Prenotazione(
           nomeOspite: nomeOspite,
           email: email,
           telefono: telefono,
           dataCheckIn: dataCheckIn,
           dataCheckOut: dataCheckOut,
           numeroOspiti: numeroOspiti,
           prezzoTotale: prezzo,
           statoPrenotazione: .confermata,
           note: note
       )
       
       viewModel.aggiungiPrenotazione(nuovaPrenotazione)
       dismiss()
   }
}

#Preview {
   AggiungiPrenotazioneView(viewModel: GestionaleViewModel())
}
