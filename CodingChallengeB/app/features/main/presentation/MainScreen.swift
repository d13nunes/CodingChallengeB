import SwiftData
import SwiftUI

struct MainScreen: View {
    @StateObject private var viewModel: MainViewModel
    @State private var searchQuery = ""

    init(viewModel: MainViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            switch viewModel.state {
            case .initial:
                EmptyView()
            case let .image(url):
                CachedAsyncImage(url: url) {
                    $0.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView().redacted(reason: .placeholder)
                } error: {
                    Text("Error")
                }
                .frame(width: 120, height: 120)
            case let .error(error):
                Text("Error: \(error)")
            case .loadingImage:
                ProgressView()
            }
            Button("Random Emoji") { fetchRandomEmoji() }
                .disabled(viewModel.state == .loadingImage)

            Button("Show All Emojis") {
                Task { @MainActor in await viewModel.send(.showEmojis) }
            }
            HStack {
                TextField("GitHub username", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { searchAvatar() }

                Button("Search Avatar") { searchAvatar() }
                    .disabled(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
                              || viewModel.state == .loadingImage)
            }
            .padding(.horizontal)

            Button("Avatars") {
                Task { @MainActor in await viewModel.send(.showAvatars) }
            }
        }
        .task {
            if viewModel.state == .initial {
                await viewModel.send(.load)
            }
        }
    }

    private func fetchRandomEmoji() {
        Task { @MainActor in await viewModel.send(.fetchRandomEmoji) }
    }

    private func searchAvatar() {
        Task { @MainActor in await viewModel.send(.search(username: searchQuery)) }
    }
}

#Preview {
    let schema = Schema([EmojiEntity.self, AvatarEntity.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let emojiRepo = EmojiRepository(remoteSource: EmojisAPI(session: URLSession.shared), localSource: container.mainContext)
    let avatarRepo = AvatarRepository(remoteSource: AvatarsAPI(session: URLSession.shared), localSource: container.mainContext)
    let router = AppRouter()
    let vm = MainViewModel(
        emojiRandomViewModel: EmojiRandomViewModel(repository: emojiRepo),
        avatarSearchViewModel: AvatarSearchViewModel(repository: avatarRepo),
        appRouter: router
    )
    MainScreen(viewModel: vm)
        .modelContainer(container)
}
