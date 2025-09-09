import SwiftUI
#if os(macOS)
import AppKit
#endif

struct UserProfileView: View {
    @StateObject private var auth = AuthService.shared
    @StateObject private var current = CurrentUser.shared
    private let repo = UserRepository()

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var role: String = "Owner"
    @State private var bio: String = ""
    @State private var imagePath: String = UserDefaults.standard.string(forKey: "userProfileImagePath") ?? ""
    @State private var showPwdSheet = false
    @State private var pwdCurrent = ""
    @State private var pwdNew = ""
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profilo Utente").font(.title2).fontWeight(.bold)
            HStack(alignment: .top, spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Nome", text: $name)
                    TextField("Email", text: $email)
                    Picker("Ruolo", selection: $role) {
                        Text("Owner").tag("Owner")
                        Text("Manager").tag("Manager")
                        Text("Staff").tag("Staff")
                    }.pickerStyle(.segmented)
                    Button("Cambia Password") { showPwdSheet = true }
                }
            }
            Text("Bio").font(.subheadline)
            TextEditor(text: $bio).frame(minHeight: 120)

            HStack {
                Button("Salva") { saveProfile() }
                    .buttonStyle(.borderedProminent)
                if saved { Text("Salvato ✅").foregroundColor(.green).font(.caption) }
                Spacer()
            }
        }
        .padding()
        .onAppear { loadCurrent() }
        .sheet(isPresented: $showPwdSheet) { pwdSheet }
    }

    private var avatar: some View {
        VStack(spacing: 8) {
            ZStack {
                if let img = loadImage(path: imagePath) {
                    img.resizable().scaledToFill()
                } else {
                    Text(initials(from: name))
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))

            Button("Scegli Immagine…") { pickImage() }
        }
    }

    private var pwdSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cambia Password").font(.headline)
            SecureField("Password attuale", text: $pwdCurrent)
            SecureField("Nuova password", text: $pwdNew)
            HStack {
                Spacer()
                Button("Annulla") { showPwdSheet = false }
                Button("Salva") {
                    if repo.changePassword(email: current.email, current: pwdCurrent, newPassword: pwdNew) {
                        showPwdSheet = false
                        pwdCurrent = ""; pwdNew = ""
                    }
                }.disabled(pwdNew.count < 4 || pwdCurrent.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func loadCurrent() {
        name = current.name
        email = current.email
        // Carica note e immagine da Core Data se disponibili
        if let u = repo.findByEmail(current.email) {
            role = (u.value(forKey: "ruolo") as? String) ?? role
            bio = (u.value(forKey: "bio") as? String) ?? ""
            imagePath = (u.value(forKey: "profileImagePath") as? String) ?? imagePath
        }
    }

    private func saveProfile() {
        let ok = repo.updateProfile(currentEmail: current.email, name: name, email: email, role: role, bio: bio, imagePath: imagePath)
        if ok {
            CurrentUser.shared.name = name
            CurrentUser.shared.email = email
            UserDefaults.standard.set(imagePath, forKey: "userProfileImagePath")
            saved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { saved = false }
        }
    }

    private func initials(from text: String) -> String {
        let comps = text.split(separator: " ")
        let first = comps.first?.first.map(String.init) ?? "M"
        let second = (comps.dropFirst().first?.first).map(String.init) ?? "B"
        return (first + second).uppercased()
    }

    #if os(macOS)
    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            imagePath = url.path
        }
    }
    private func loadImage(path: String) -> Image? {
        guard !path.isEmpty, let img = NSImage(contentsOfFile: path) else { return nil }
        return Image(nsImage: img)
    }
    #else
    private func pickImage() {}
    private func loadImage(path: String) -> Image? { nil }
    #endif
}
