import SwiftUI

struct AvatarHistoryView: View {
    @StateObject private var viewModel: AvatarHistoryViewModel

    init(viewModel: AvatarHistoryViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        switch viewModel.state {
        case .initial, .loading:
            ProgressView()
        case let .loaded(avatars):
            loadedView(avatars: avatars)
        case let .error(message):
            Text("Error: \(message)")
                .foregroundStyle(.red)
                .font(.caption)
        }
    }

    @ViewBuilder
    private func loadedView(avatars: [AvatarValue]) -> some View {
        if avatars.isEmpty {
            Text("No previous searches")
                .foregroundStyle(.secondary)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(avatars) { avatar in
                        AvatarCardView(username: avatar.username, avatarUrl: avatar.avatarUrl)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
