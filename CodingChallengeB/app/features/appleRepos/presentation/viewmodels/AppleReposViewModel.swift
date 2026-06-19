import Combine
import Foundation

enum AppleReposViewState {
    case initial
    case loading
    case loaded([RepoValue], isLoadingMore: Bool, canLoadMore: Bool)
    case error(String)
}

enum AppleReposViewEvents {
    case load
    case loadMore
    case refresh
}

@MainActor @Observable
final class AppleReposViewModel: ViewModel<AppleReposViewState, AppleReposViewEvents> {
    var state: AppleReposViewState = .initial

    private let repository: AppleRepoRepositoryProtocol
    private var currentPage = 1
    private let pageSize = 10

    init(repository: AppleRepoRepositoryProtocol) {
        self.repository = repository
    }

    func send(_ event: AppleReposViewEvents) async {
        switch event {
        case .load:
            await doLoad(isRefresh: false)
        case .loadMore:
            await doLoadMore()
        case .refresh:
            await doLoad(isRefresh: true)
        }
    }

    private func doLoad(isRefresh: Bool) async {
        currentPage = 1
        if !isRefresh {
            state = .loading
        }
        do {
            let result = await repository.fetch(page: currentPage, pageSize: pageSize)
            switch result {
            case let .success((repos, hasMore)):
                state = .loaded(repos, isLoadingMore: false, canLoadMore: hasMore)
            case let .failure(error):
                state = .error(error.localizedDescription)
            }
        } catch {
            print("error \(error)")
        }
    }

    private func doLoadMore() async {
        guard case let .loaded(existing, isLoadingMore, canLoadMore) = state, canLoadMore, !isLoadingMore else {
            return
        }
        state = .loaded(existing, isLoadingMore: true, canLoadMore: canLoadMore)
        currentPage += 1
        let result = await repository.fetch(page: currentPage, pageSize: pageSize)
        switch result {
        case let .success((repos, hasMore)):
            state = .loaded(existing + repos, isLoadingMore: false, canLoadMore: hasMore)
        case let .failure(error):
            // TODO: Handle error with a call out instead of showing an error
            state = .error(error.localizedDescription)
        }
    }
}
