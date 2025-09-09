import SwiftUI

struct StruttureView: View {
    @StateObject private var repo = StrutturaRepository()
    @State private var showingAdd = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Strutture").font(.title2).fontWeight(.bold)
                Spacer()
                Button("Nuova Struttura") { showingAdd = true }
            }.padding()
            List {
                ForEach(repo.strutture, id: \.objectID) { s in
                    HStack(alignment: .center, spacing: 12) {
                        if let p = s.value(forKey: "imagePath") as? String, !p.isEmpty, let img = loadImage(p) {
                            img.resizable().scaledToFill().frame(width: 36, height: 36).clipShape(Circle())
                        }
                        VStack(alignment: .leading) {
                            Text(s.nome ?? "Senza nome").font(.headline)
                            Text("\(s.indirizzo ?? "") - \(s.citta ?? "")").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Imposta Attiva") { repo.setActive(s) }
                        Button("Modifica") { editing = s }
                        Button(role: .destructive, action: { toDelete = s }) { Text("Elimina") }
                    }
                }
            }
        }
        .onAppear { repo.load() }
        .sheet(isPresented: $showingAdd) { NuovaStrutturaView(repo: repo) }
        .sheet(item: $editing) { s in EditStrutturaView(repo: repo, struttura: s) }
        .alert("Eliminare la struttura?", isPresented: Binding(get: { toDelete != nil }, set: { v in if !v { toDelete = nil } })) {
            Button("Elimina", role: .destructive) {
                if let s = toDelete { repo.delete(s) }
                toDelete = nil
            }
            Button("Annulla", role: .cancel) { toDelete = nil }
        }
    }
    @State private var editing: CDStruttura? = nil
    @State private var toDelete: CDStruttura? = nil

    #if os(macOS)
    private func loadImage(_ path: String) -> Image? {
        if let img = NSImage(contentsOfFile: path) { return Image(nsImage: img) }
        return nil
    }
    #else
    private func loadImage(_ path: String) -> Image? { nil }
    #endif
}

private struct NuovaStrutturaView: View {
    @ObservedObject var repo: StrutturaRepository
    @Environment(\.dismiss) private var dismiss
    @State private var nome = ""
    @State private var indirizzo = ""
    @State private var citta = ""
    @State private var camere = 1
    @State private var bookingId = ""
    @State private var bookingUrl = ""
    @State private var note = ""
    @State private var imagePath = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nuova Struttura").font(.headline)
            TextField("Nome", text: $nome)
            TextField("Indirizzo", text: $indirizzo)
            TextField("Città", text: $citta)
            Stepper("Camere totali: \(camere)", value: $camere, in: 1...50)
            Divider()
            Text("Booking.com (opzionale)").font(.subheadline)
            TextField("Property ID", text: $bookingId)
            TextField("URL pagina struttura", text: $bookingUrl)
            Divider()
            Text("Note").font(.subheadline)
            TextEditor(text: $note).frame(minHeight: 100)
            HStack {
                TextField("Immagine (percorso)", text: $imagePath)
                Button("Scegli…") { imagePath = pickImage() ?? imagePath }
            }
            HStack {
                Spacer()
                Button("Annulla") { dismiss() }
                Button("Salva") {
                    repo.add(nome: nome, indirizzo: indirizzo, citta: citta, camere: camere,
                             bookingId: bookingId.isEmpty ? nil : bookingId,
                             bookingUrl: bookingUrl.isEmpty ? nil : bookingUrl,
                             note: note.isEmpty ? nil : note,
                             imagePath: imagePath.isEmpty ? nil : imagePath)
                    dismiss()
                }.disabled(nome.isEmpty)
            }
        }
        .padding()
        .frame(width: 420)
    }

    #if os(macOS)
    private func pickImage() -> String? {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.jpeg, .png]
        p.allowsMultipleSelection = false
        p.canChooseDirectories = false
        return p.runModal() == .OK ? p.url?.path : nil
    }
    #else
    private func pickImage() -> String? { nil }
    #endif
}

private struct EditStrutturaView: View {
    @ObservedObject var repo: StrutturaRepository
    @Environment(\.dismiss) private var dismiss
    let struttura: CDStruttura
    @State private var nome = ""
    @State private var indirizzo = ""
    @State private var citta = ""
    @State private var camere = 1
    @State private var bookingId = ""
    @State private var bookingUrl = ""
    @State private var note = ""
    @State private var imagePath = ""
    @State private var photos: [NSManagedObject] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modifica Struttura").font(.headline)
            TextField("Nome", text: $nome)
            TextField("Indirizzo", text: $indirizzo)
            TextField("Città", text: $citta)
            Stepper("Camere totali: \(camere)", value: $camere, in: 1...50)
            Divider()
            Text("Booking.com (opzionale)").font(.subheadline)
            TextField("Property ID", text: $bookingId)
            TextField("URL pagina struttura", text: $bookingUrl)
            Divider()
            Text("Note").font(.subheadline)
            TextEditor(text: $note).frame(minHeight: 100)
            HStack {
                TextField("Immagine (percorso)", text: $imagePath)
                Button("Scegli…") { imagePath = pickImage() ?? imagePath }
            }
            Divider()
            Text("Galleria Immagini").font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(photos, id: \.objectID) { ph in
                        ZStack(alignment: .topTrailing) {
                            if let p = ph.value(forKey: "path") as? String, let img = loadImage(p) {
                                img.resizable().scaledToFill().frame(width: 90, height: 70).clipped().cornerRadius(6)
                            } else {
                                Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 90, height: 70).cornerRadius(6)
                            }
                            Button(role: .destructive) { repo.deletePhoto(ph); reloadPhotos() } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button("+ Aggiungi foto…") { addPhotos() }
                }
            }
            HStack { Spacer()
                Button("Annulla") { dismiss() }
                Button("Salva") {
                    repo.update(struttura,
                                nome: nome,
                                indirizzo: indirizzo,
                                citta: citta,
                                camere: camere,
                                bookingId: bookingId.isEmpty ? nil : bookingId,
                                bookingUrl: bookingUrl.isEmpty ? nil : bookingUrl,
                                note: note.isEmpty ? nil : note,
                                imagePath: imagePath.isEmpty ? nil : imagePath)
                    dismiss()
                }.disabled(nome.isEmpty)
            }
        }
        .padding()
        .frame(width: 420)
        .onAppear {
            nome = struttura.nome ?? ""
            indirizzo = struttura.indirizzo ?? ""
            citta = struttura.citta ?? ""
            camere = Int(struttura.camereTotali)
            bookingId = struttura.bookingPropertyId ?? ""
            bookingUrl = struttura.bookingUrl ?? ""
            note = (struttura.value(forKey: "note") as? String) ?? ""
            imagePath = (struttura.value(forKey: "imagePath") as? String) ?? ""
            reloadPhotos()
        }
    }

    #if os(macOS)
    private func pickImage() -> String? {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.jpeg, .png]
        p.allowsMultipleSelection = false
        p.canChooseDirectories = false
        return p.runModal() == .OK ? p.url?.path : nil
    }
    private func loadImage(_ path: String) -> Image? {
        if let img = NSImage(contentsOfFile: path) { return Image(nsImage: img) }
        return nil
    }
    private func addPhotos() {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.jpeg, .png]
        p.allowsMultipleSelection = true
        p.canChooseDirectories = false
        if p.runModal() == .OK {
            let paths = p.urls.map { $0.path }
            repo.addPhotos(paths, to: struttura)
            reloadPhotos()
        }
    }
    private func reloadPhotos() { photos = repo.photos(for: struttura) }
    #else
    private func pickImage() -> String? { nil }
    private func loadImage(_ path: String) -> Image? { nil }
    #endif
}
