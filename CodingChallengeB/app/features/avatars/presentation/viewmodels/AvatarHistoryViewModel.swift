import Combine
import Foundation

enum AvatarHistoryState {
    case initial
    case loading
    case loaded([AvatarValue])
    case error(String)
}

enum AvatarHistoryEvents {
    case load
    case delete(AvatarValue)
}

@MainActor @Observable
final class AvatarHistoryViewModel: ViewModel<AvatarHistoryState, AvatarHistoryEvents> {
    var state: AvatarHistoryState

    private let repository: AvatarRepositoryProtocol

    init(repository: AvatarRepositoryProtocol, state: AvatarHistoryState = .initial) {
        self.repository = repository
        self.state = state
    }

    func send(_ event: AvatarHistoryEvents) async {
        switch event {
        case .load:
            state = .loading
            let result = await repository.fetchHistory()
            switch result {
            case let .success(avatars):
                state = .loaded(avatars)
            case let .failure(error):
                state = .error(error.localizedDescription)
            }
        case let .delete(avatar):
            let result = await repository.delete(username: avatar.username)
            switch result {
            case .success:
                if case let .loaded(avatars) = state {
                    state = .loaded(avatars.filter { $0.id != avatar.id })
                }
            case let .failure(error):
                state = .error(error.localizedDescription)
            }
        }
    }
}
