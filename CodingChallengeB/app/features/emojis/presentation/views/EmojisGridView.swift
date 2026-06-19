import SwiftData
import SwiftUI

struct EmojisGridView: View {
    @State private var viewModel: EmojisViewModel

    init(viewModel: EmojisViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .initial:
                Text("Initial")
            case .loading:
                Text("Loading...")
            case let .loaded(emojis):
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)], spacing: 16) {
                        ForEach(emojis, id: \.name) { emoji in
                            EmojiCardView(name: emoji.name, imageURL: emoji.url)
                                .frame(height: 120)
                                .onTapGesture {
                                    Task {
                                        await viewModel.send(.hideEmoji(emoji: emoji))
                                    }
                                }
                        }
                    }
                }
            case let .error(error):
                VStack {
                    Text("Error: \(error)")
                    Button("Retry") {
                        load()
                    }
                }
            }
        }
        .refreshable {
            load(forceRefresh: true)
        }
        .task {
            load()
        }
    }

    private func load(forceRefresh: Bool = false) {
        Task {
            await self.viewModel.send(.load(forceRefresh: forceRefresh))
        }
    }
}

#Preview {
    let schema = Schema([EmojiEntity.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let repository = EmojiRepository(remoteSource: EmojisAPI(session: URLSession.shared), localSource: container.mainContext)

    EmojisGridView(viewModel: EmojisViewModel(repository: repository))
        .modelContainer(container)
}
