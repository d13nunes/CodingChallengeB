import SwiftData
import SwiftUI

struct EmojiRandomView: View {
    @StateObject private var viewModel: EmojiRandomViewModel
    @State private var isEnable = false

    init(viewModel: EmojiRandomViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .initial, .loadingRandomEmoji:
                ProgressView()
            case let .loaded(emoji):
                CachedAsyncImage(url: emoji.url) {
                    $0.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView().redacted(reason: .placeholder)
                } error: {
                    Text("Error")
                }
                .frame(width: 120, height: 120)
                Button("Random Emoji") {
                    Task { @MainActor in
                        await getRandomEmoji()
                    }
                }
            case let .error(error):
                Text("Error: \(error)")
                Button("Retry") {
                    Task {
                        await getRandomEmoji()
                    }
                }
            }

        }.task {
            await getRandomEmoji()
        }
    }

    private func getRandomEmoji() async {
        await viewModel.send(.loadRandomEmoji)
    }
}

#Preview {
    let schema = Schema([EmojiEntity.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let repository = EmojiRepository(remoteSource: EmojisAPI(session: URLSession.shared), localSource: container.mainContext)
    EmojiRandomView(viewModel: EmojiRandomViewModel(repository: repository))
        .modelContainer(container)
}
