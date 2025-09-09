import SwiftUI
#if os(macOS)
import AppKit
#endif

struct UserStructureHeader: View {
    @ObservedObject private var currentUser = CurrentUser.shared

    private var strutturaName: String {
        UserDefaults.standard.string(forKey: "activeStrutturaName") ?? ""
    }

    private var userImagePath: String? {
        UserDefaults.standard.string(forKey: "userProfileImagePath")
    }

    private var strutturaImagePath: String? {
        UserDefaults.standard.string(forKey: "activeStrutturaImagePath")
    }

    var body: some View {
        HStack(spacing: 16) {
            ProfileCard(title: currentUser.name.isEmpty ? "Utente" : currentUser.name,
                        subtitle: currentUser.email,
                        image: loadImage(path: userImagePath),
                        placeholderText: initials(from: currentUser.name))

            ProfileCard(title: strutturaName.isEmpty ? "Struttura" : strutturaName,
                        subtitle: "Attiva",
                        image: loadImage(path: strutturaImagePath),
                        placeholderText: initials(from: strutturaName))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private func initials(from text: String) -> String {
        let comps = text.split(separator: " ")
        let first = comps.first?.first.map(String.init) ?? "M"
        let second = (comps.dropFirst().first?.first).map(String.init) ?? "B"
        return (first + second).uppercased()
    }

    private func loadImage(path: String?) -> Image? {
        guard let path, !path.isEmpty else { return nil }
        #if os(macOS)
        if let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
}

private struct ProfileCard: View {
    let title: String
    let subtitle: String
    let image: Image?
    let placeholderText: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(placeholderText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.blue)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "—" : title)
                    .font(.headline)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

