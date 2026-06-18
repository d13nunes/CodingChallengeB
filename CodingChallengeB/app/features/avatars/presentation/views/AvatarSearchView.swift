import SwiftUI

struct AvatarSearchView: View {
    @StateObject private var viewModel: AvatarSearchViewModel
    @State private var query: String = ""

    init(viewModel: AvatarSearchViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("GitHub username", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { search() }

                Button("Search") { search() }
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.state == .loading)
            }

            switch viewModel.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
                    .frame(height: 100)
            case let .loaded(avatar):
                VStack(spacing: 8) {
                    CachedAsyncImage(url: avatar.avatarUrl) {
                        $0.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    } error: {
                        Image(systemName: "person.fill")
                            .resizable()
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())

                    Text(avatar.username)
                        .font(.headline)
                }
                .frame(height: 140)
            case let .error(message):
                Text("Error: \(message)")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .frame(height: 40)
            }
        }
    }

    private func search() {
        Task { await viewModel.send(.search(username: query)) }
    }
}

extension AvatarSearchState: Equatable {
    static func == (lhs: AvatarSearchState, rhs: AvatarSearchState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case let (.loaded(a), .loaded(b)): return a.id == b.id
        case let (.error(a), .error(b)): return a == b
        default: return false
        }
    }
}
