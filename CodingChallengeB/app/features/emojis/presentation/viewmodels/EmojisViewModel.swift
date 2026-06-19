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
    case hideEmoji(emoji: EmojiValue)
}

@MainActor @Observable
final class EmojisViewModel: ViewModel<EmojisViewModelState, EmojisViewModelEvents> {
    var state: EmojisViewModelState

    private let repository: EmojiRepositoryProtocol
    private var hiddedEmojisId: Set<UUID> = []

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
        case let .hideEmoji(emoji):
            hiddedEmojisId.insert(emoji.id)
            if case let .loaded(emojis) = state {
                state = .loaded(emojis.filter { !hiddedEmojisId.contains($0.id) })
            }
        }
    }

    private func doLoad(forceRefresh: Bool) async {
        state = .loading
        let response = await repository.fetch(useCache: !forceRefresh)
        hiddedEmojisId.removeAll()
        switch response {
        case let .success(emojis):
            state = .loaded(emojis)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }
}
