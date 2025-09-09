import Foundation
import CoreData
import CryptoKit

@MainActor
final class UserRepository: ObservableObject {
    private let context = CoreDataManager.shared.viewContext

    func users() -> [CDUtente] {
        let req = NSFetchRequest<CDUtente>(entityName: "CDUtente")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }

    func findByEmail(_ email: String) -> CDUtente? {
        let req = NSFetchRequest<CDUtente>(entityName: "CDUtente")
        req.predicate = NSPredicate(format: "email ==[c] %@", email)
        return try? context.fetch(req).first
    }

    func register(name: String, email: String, password: String) -> Bool {
        guard findByEmail(email) == nil else { return false }
        let salt = randomSalt()
        let hash = hashPassword(password, salt: salt)
        let u = CDUtente(context: context)
        u.id = UUID(); u.nome = name; u.email = email
        u.passwordHash = hash; u.salt = salt; u.createdAt = Date()
        do { try context.save(); return true } catch { return false }
    }

    func validate(email: String, password: String) -> Bool {
        guard let u = findByEmail(email), let salt = u.salt, let hash = u.passwordHash else { return false }
        return hashPassword(password, salt: salt) == hash
    }

    func updateProfile(currentEmail: String, name: String, email: String, role: String?, bio: String?, imagePath: String?) -> Bool {
        guard let u = findByEmail(currentEmail) else { return false }
        // Se cambia email, verifica che non esista già
        if email.lowercased() != currentEmail.lowercased(), findByEmail(email) != nil { return false }
        u.nome = name
        u.email = email.lowercased()
        u.setValue(role, forKey: "ruolo")
        u.setValue(bio, forKey: "bio")
        u.setValue(imagePath, forKey: "profileImagePath")
        do { try context.save(); return true } catch { return false }
    }

    func changePassword(email: String, current: String, newPassword: String) -> Bool {
        guard let u = findByEmail(email), let salt = u.salt, let hash = u.passwordHash else { return false }
        guard hashPassword(current, salt: salt) == hash else { return false }
        let newSalt = randomSalt()
        let newHash = hashPassword(newPassword, salt: newSalt)
        u.salt = newSalt
        u.passwordHash = newHash
        do { try context.save(); return true } catch { return false }
    }

    private func randomSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    private func hashPassword(_ password: String, salt: Data) -> Data {
        var data = Data()
        data.append(salt)
        data.append(password.data(using: .utf8) ?? Data())
        let digest = SHA256.hash(data: data)
        return Data(digest)
    }
}
