import SwiftUI
import UIKit

struct CachedAsyncImage<Content: View, Placeholder: View, ErrorView: View>: View {
    let url: URL?
    let scale: CGFloat
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    let error: () -> ErrorView

    @State private var cachedImage: UIImage?
    @State private var cachedURL: URL?

    init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder error: @escaping () -> ErrorView
    ) {
        self.url = url
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
        self.error = error
    }

    var body: some View {
        return Group {
            if let cachedImage, cachedURL == url {
                content(Image(uiImage: cachedImage))
            } else {
                AsyncImage(url: url, scale: scale) { phase in
                    switch phase {
                    case let .success(image):
                        content(image)
                            .onAppear {
                                if let url { saveToCache(from: url) }
                            }
                    case .failure:
                        error()
                    default:
                        placeholder()
                    }
                }
            }
        }
        .onAppear {
            loadFromCache()
        }
    }

    private func loadFromCache() {
        guard let url else { return }
        if let cached = ImageCache.shared.object(forKey: url as NSURL) {
            cachedImage = cached
        }
    }

    private func saveToCache(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        ImageCache.shared.setObject(uiImage, forKey: url as NSURL)
                        if cachedImage == nil {
                            cachedImage = uiImage
                        }
                    }
                }
            } catch {
                print("Image caching failed: \(error)")
            }
        }
    }
}
