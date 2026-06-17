import Combine
import Foundation

enum EmojisViewModelState {
    case initial
    case loading
    case loaded([EmojiValue])
    case error(String)
}

enum EmojisViewModelEvents {
    case load(forceRefresh: Bool = false)
}

@MainActor
final class EmojisViewModel: ViewModel<EmojisViewModelState, EmojisViewModelEvents> {
    @Published var state: EmojisViewModelState

    private let repository: EmojiRepositoryProtocol
    init(
        repository: EmojiRepositoryProtocol,
        state: EmojisViewModelState = .initial
    ) {
        self.repository = repository
        self.state = state
    }

    func send(_ event: EmojisViewModelEvents) async {
        switch event {
        case let .load(forceRefresh):
            await doLoad(forceRefresh: forceRefresh)
        }
    }

    private func doLoad(forceRefresh: Bool) async {
        state = .loading
        let response = await repository.fetch(useCache: !forceRefresh)
        switch response {
        case let .success(emojis):
            state = .loaded(emojis)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }
}
