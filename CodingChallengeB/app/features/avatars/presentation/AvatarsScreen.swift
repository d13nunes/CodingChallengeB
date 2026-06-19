import SwiftData
import SwiftUI

struct AvatarsScreen: View {
    @State private var historyViewModel: AvatarHistoryViewModel

    init(historyViewModel: AvatarHistoryViewModel) {
        _historyViewModel = .init(wrappedValue: historyViewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Previous Searches")
                .font(.headline)
                .padding(.horizontal)

            AvatarHistoryView(viewModel: historyViewModel)
        }
        .task {
            await historyViewModel.send(.load)
        }
    }
}

#Preview {
    let schema = Schema([EmojiEntity.self, AvatarEntity.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let repo = AvatarRepository(
        remoteSource: AvatarsAPI(session: URLSession.shared),
        localSource: container.mainContext
    )
    AvatarsScreen(historyViewModel: AvatarHistoryViewModel(repository: repo))
        .modelContainer(container)
}
