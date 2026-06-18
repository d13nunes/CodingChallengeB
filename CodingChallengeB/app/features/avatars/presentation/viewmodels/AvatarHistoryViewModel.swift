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
}

@MainActor
final class AvatarHistoryViewModel: ViewModel<AvatarHistoryState, AvatarHistoryEvents> {
    @Published var state: AvatarHistoryState

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
        }
    }
}
