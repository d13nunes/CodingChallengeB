import Combine
import Foundation

enum EmojiRandomViewState {
    case initial
    case loadingRandomEmoji
    case loaded(EmojiValue)
    case error(String)
}

enum EmojiRandomViewModelEvents {
    case loadRandomEmoji
}

@MainActor
class EmojiRandomViewModel: ViewModel<EmojiRandomViewState, EmojiRandomViewModelEvents> {
    @Published var state: EmojiRandomViewState

    private let repository: EmojiRepositoryProtocol

    init(repository: EmojiRepositoryProtocol) {
        self.repository = repository
        state = .initial
    }

    func send(_ event: EmojiRandomViewModelEvents) async {
        switch event {
        case .loadRandomEmoji:
            await getRandomEmoji()
        }
    }

    private func getRandomEmoji() async {
        state = .loadingRandomEmoji
        let result = await repository.fetchRandom()
        switch result {
        case let .success(emoji):
            state = .loaded(emoji)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }
}
