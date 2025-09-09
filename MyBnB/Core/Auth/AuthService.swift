import Foundation
import LocalAuthentication

final class CurrentUser: ObservableObject {
    static let shared = CurrentUser(); private init() {}
    @Published var email: String = ""
    @Published var name: String = ""
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    private init() {
        isAuthenticated = false
    }

    @Published var isAuthenticated: Bool
    private let userRepo = UserRepository()
    var hasUsers: Bool { !userRepo.users().isEmpty }

    func register(name: String, email: String, password: String) -> Bool {
        let ok = userRepo.register(name: name, email: email.lowercased(), password: password)
        if ok { setCurrent(email: email.lowercased()) }
        isAuthenticated = ok
        return ok
    }

    func login(email: String, password: String) -> Bool {
        let ok = userRepo.validate(email: email.lowercased(), password: password)
        if ok { setCurrent(email: email.lowercased()) }
        isAuthenticated = ok
        return ok
    }

    func logout() { isAuthenticated = false; setCurrent(email: "") }

    func loginWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Accedi a MyBnB")
                isAuthenticated = true
                return true
            } catch { return false }
        }
        return false
    }

    private func setCurrent(email: String) {
        let current = CurrentUser.shared
        current.email = email
        if let u = userRepo.findByEmail(email) {
            current.name = u.nome ?? ""
            if let path = u.value(forKey: "profileImagePath") as? String, !path.isEmpty {
                UserDefaults.standard.set(path, forKey: "userProfileImagePath")
            }
        } else {
            current.name = ""
        }
    }
}
