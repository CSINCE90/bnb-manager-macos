import SwiftUI
#if os(macOS)
import AppKit
#endif

struct StructurePhotosCarousel: View {
    @StateObject private var repo = StrutturaRepository()
    @State private var photos: [NSManagedObject] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Galleria Struttura")
                    .font(.headline)
                if !photos.isEmpty {
                    Text("(\(photos.count))").foregroundColor(.secondary).font(.caption)
                }
                Spacer()
            }

            if photos.isEmpty {
                Text("Nessuna immagine. Aggiungile in Strutture → Modifica.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.06)))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(photos, id: \.objectID) { ph in
                            let path = (ph.value(forKey: "path") as? String) ?? ""
                            ZStack {
                                if let img = loadImage(path) {
                                    img.resizable().scaledToFill()
                                } else {
                                    Rectangle().fill(Color.gray.opacity(0.15))
                                }
                            }
                            .frame(width: 260, height: 160)
                            .clipped()
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .onAppear { loadActivePhotos() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ActiveStrutturaChanged"))) { _ in
            loadActivePhotos()
        }
    }

    private func loadActivePhotos() {
        if let s = repo.activeStructure() {
            self.photos = repo.photos(for: s)
        } else {
            self.photos = []
        }
    }

    #if os(macOS)
    private func loadImage(_ path: String) -> Image? {
        guard let img = NSImage(contentsOfFile: path) else { return nil }
        return Image(nsImage: img)
    }
    #else
    private func loadImage(_ path: String) -> Image? { nil }
    #endif
}

