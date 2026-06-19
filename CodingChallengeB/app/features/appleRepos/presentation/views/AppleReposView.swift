import SwiftUI

struct AppleReposView: View {
    @State private var viewModel: AppleReposViewModel

    init(viewModel: AppleReposViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            Group {
                switch viewModel.state {
                case .initial:
                    EmptyView()
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .loaded(repos, isLoadingMore, hasMore):
                    repoList(repos: repos, isLoadingMore: isLoadingMore, hasMore: hasMore)
                case let .error(message):
                    VStack(spacing: 12) {
                        Text("Error: \(message)")
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.send(.load) }
                        }
                    }
                    .padding()
                }
            }
        }
        .refreshable {
            await viewModel.send(.refresh)
        }
        .task {
            if case .initial = viewModel.state {
                await viewModel.send(.load)
            }
        }
        .navigationTitle("Apple Repos")
    }

    private func repoList(repos: [RepoValue], isLoadingMore: Bool, hasMore: Bool) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
            ForEach(repos, id: \.id) { repo in
                RepoRowView(repo: repo)
                    .onAppear { [viewModel] in
                        if hasMore && repo.id == repos.last?.id {
                            Task { await viewModel.send(.loadMore) }
                        }
                    }
            }
            if isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
}
