import Combine
import SwiftData
import SwiftUI

struct MainScreen: View {
    @State private var viewModel: MainViewModel
    @State private var searchQuery = ""
    @FocusState private var isInputFocused: Bool

    init(viewModel: MainViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Group {
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
                case let .error(error):
                    Text("Error: \(error)")
                case .loadingImage:
                    ProgressView()
                }
            }.frame(width: 120, height: 120)
            Button("Random Emoji") {
                fetchRandomEmoji()
            }
            .disabled(viewModel.state == .loadingImage)
            Button("Show All Emojis") {
                isInputFocused = false
                Task { @MainActor in await viewModel.send(.showEmojis) }
            }
            HStack {
                TextField("GitHub username", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isInputFocused)
                    .onSubmit { searchAvatar() }
                    .frame(maxWidth: 200)

                Button("Search Avatar") { searchAvatar() }
                    .disabled(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
                        || viewModel.state == .loadingImage)
            }
            .padding(.horizontal)
            Button("Avatars") {
                isInputFocused = false
                Task { @MainActor in await viewModel.send(.showAvatars) }
            }
            Button("Apple Repos") {
                isInputFocused = false
                Task { @MainActor in await viewModel.send(.showAppleRepos) }
            }
        }
        .task {
            if viewModel.state == .initial {
                await viewModel.send(.load)
            }
        }
    }

    private func fetchRandomEmoji() {
        isInputFocused = false
        Task { @MainActor in await viewModel.send(.fetchRandomEmoji) }
    }

    private func searchAvatar() {
        isInputFocused = false
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
        emojiRepository: emojiRepo,
        avatarRepository: avatarRepo,
        appRouter: router
    )
    MainScreen(viewModel: vm)
        .modelContainer(container)
}
