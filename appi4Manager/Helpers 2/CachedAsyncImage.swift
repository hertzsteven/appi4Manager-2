import SwiftUI

// MARK: - ImageCache

/// A shared image cache using URLCache for persistent storage
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    
    private let cache: URLCache
    
    private init() {
        // 50MB memory, 200MB disk cache
        cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "app_icon_cache"
        )
    }
    
    func cachedImage(for url: URL) -> UIImage? {
        let request = URLRequest(url: url)
        guard let cachedResponse = cache.cachedResponse(for: request),
              let image = UIImage(data: cachedResponse.data) else {
            return nil
        }
        return image
    }
    
    func store(_ data: Data, for url: URL, response: URLResponse) {
        let request = URLRequest(url: url)
        let cachedResponse = CachedURLResponse(response: response, data: data)
        cache.storeCachedResponse(cachedResponse, for: request)
    }
}

// MARK: - ImageLoader

/// An observable image loader that fetches and caches images
@MainActor
@Observable
final class ImageLoader {
    
    enum LoadState {
        case loading
        case success(Image)
        case failure(Error)
    }
    
    private(set) var state: LoadState = .loading
    private var loadTask: Task<Void, Never>?
    
    func load(url: URL?) async {
        loadTask?.cancel()
        
        guard let url else {
            state = .failure(URLError(.badURL))
            return
        }
        
        state = .loading
        
        // Check cache first
        if let cachedImage = ImageCache.shared.cachedImage(for: url) {
            state = .success(Image(uiImage: cachedImage))
            return
        }
        
        // Download image
        loadTask = Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard !Task.isCancelled else { return }
                
                guard let uiImage = UIImage(data: data) else {
                    state = .failure(URLError(.cannotDecodeContentData))
                    return
                }
                
                // Cache the image
                ImageCache.shared.store(data, for: url, response: response)
                
                state = .success(Image(uiImage: uiImage))
            } catch {
                if !Task.isCancelled {
                    state = .failure(error)
                }
            }
        }
    }
    
    func cancel() {
        loadTask?.cancel()
    }
}

// MARK: - CachedAsyncImage

/// A drop-in replacement for AsyncImage with persistent caching
/// Uses URLCache for memory and disk caching of downloaded images
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content
    
    @State private var loader = ImageLoader()
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .task(id: url) {
                await loader.load(url: url)
            }
            .onDisappear {
                loader.cancel()
            }
    }
    
    private var phase: AsyncImagePhase {
        switch loader.state {
        case .loading:
            return .empty
        case .success(let image):
            return .success(image)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage {
    
    /// Creates a cached async image with a simple content/placeholder pattern
    init<I: View, P: View>(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P> {
        self.init(url: url) { phase in
            if case .success(let image) = phase {
                content(image)
            } else {
                placeholder()
            }
        }
    }
}
