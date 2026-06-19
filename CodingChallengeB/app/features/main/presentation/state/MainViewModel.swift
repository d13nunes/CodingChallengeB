import Combine
import Foundation

enum MainViewState: Equatable {
    case initial
    case loadingImage
    case image(url: URL?)
    case error(String)
}

enum MainViewEvents {
    case load
    case showEmojis
    case fetchRandomEmoji
    case showAvatars
    case showAppleRepos
    case search(username: String)
}

@MainActor @Observable
final class MainViewModel: ViewModel<MainViewState, MainViewEvents> {
    var state: MainViewState = .initial

    private let emojiRepository: EmojiRepositoryProtocol
    private let avatarRepository: AvatarRepositoryProtocol
    private let appRouter: AppRouter

    init(
        emojiRepository: EmojiRepositoryProtocol,
        avatarRepository: AvatarRepositoryProtocol,
        appRouter: AppRouter
    ) {
        self.emojiRepository = emojiRepository
        self.avatarRepository = avatarRepository
        self.appRouter = appRouter
    }

    func send(_ event: MainViewEvents) async {
        switch event {
        case .load, .fetchRandomEmoji:
            await loadRandomEmoji()
        case let .search(username):
            await search(username: username)
        case .showEmojis:
            appRouter.push(.emojiesList)
        case .showAvatars:
            appRouter.push(.avatarsList)
        case .showAppleRepos:
            appRouter.push(.appleRepos)
        }
    }

    private func loadRandomEmoji() async {
        state = .loadingImage
        switch await emojiRepository.fetchRandom() {
        case let .success(emoji):
            state = .image(url: emoji.url)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }

    private func search(username: String) async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        state = .loadingImage
        switch await avatarRepository.searchUser(username: trimmed.lowercased()) {
        case let .success(avatar):
            state = .image(url: avatar.avatarUrl)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }
}
