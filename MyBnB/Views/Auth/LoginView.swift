import SwiftUI

struct LoginView: View {
    @StateObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var registration = false
    @State private var showError = false

    var body: some View {
        VStack(spacing: 16) {
            Text("MyBnB").font(.largeTitle).fontWeight(.bold)
            if !auth.hasUsers || registration { onboarding }
            else { login }
        }
        .frame(minWidth: 380)
        .padding(24)
    }

    private var onboarding: some View {
        VStack(spacing: 12) {
            Text("Crea account")
                .font(.headline)
            TextField("Nome", text: $name)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            HStack {
                Button("Annulla") { registration = false }
                Button("Registrati") {
                    _ = auth.register(name: name, email: email, password: password)
                }.disabled(name.isEmpty || email.isEmpty || password.count < 4)
            }
        }
    }

    private var login: some View {
        VStack(spacing: 12) {
            Text("Accedi")
                .font(.headline)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            HStack {
                Button("Accedi") {
                    showError = !auth.login(email: email, password: password)
                }
                Button("Touch ID / Face ID") {
                    Task { _ = await auth.loginWithBiometrics() }
                }
                Button("Registrati") { registration = true }
            }
            if showError { Text("Password errata").foregroundColor(.red).font(.caption) }
        }
    }
}
