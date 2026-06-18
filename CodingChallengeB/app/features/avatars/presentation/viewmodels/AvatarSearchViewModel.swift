import Combine
import Foundation

enum AvatarSearchState {
    case idle
    case loading
    case loaded(AvatarValue)
    case error(String)
}

enum AvatarSearchEvents {
    case search(username: String)
}

@MainActor
final class AvatarSearchViewModel: ViewModel<AvatarSearchState, AvatarSearchEvents> {
    @Published var state: AvatarSearchState

    private let repository: AvatarRepositoryProtocol

    init(repository: AvatarRepositoryProtocol, state: AvatarSearchState = .idle) {
        self.repository = repository
        self.state = state
    }

    func send(_ event: AvatarSearchEvents) async {
        switch event {
        case let .search(username):
            guard !username.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            state = .loading
            let result = await repository.searchUser(username: username.lowercased())
            switch result {
            case let .success(avatar):
                state = .loaded(avatar)
            case let .failure(error):
                state = .error(error.localizedDescription)
            }
        }
    }
}
