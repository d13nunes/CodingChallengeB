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
    case search(username: String)
}

@MainActor
class MainViewModel: ViewModel<MainViewState, MainViewEvents> {
    @Published var state: MainViewState

    private let emojiRandomViewModel: EmojiRandomViewModel
    private let avatarSearchViewModel: AvatarSearchViewModel
    private let appRouter: AppRouter
    private var cancellables = Set<AnyCancellable>()

    init(emojiRandomViewModel: EmojiRandomViewModel, avatarSearchViewModel: AvatarSearchViewModel, appRouter: AppRouter) {
        self.emojiRandomViewModel = emojiRandomViewModel
        self.avatarSearchViewModel = avatarSearchViewModel
        self.appRouter = appRouter
        state = .initial

        emojiRandomViewModel.$state
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case let .loaded(emoji):
                    self.state = .image(url: emoji.url)
                case .error(let error):
                    self.state = .error(error)
                default:
                    break
                }
            }
            .store(in: &cancellables)

        avatarSearchViewModel.$state
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .loading:
                    self.state = .loadingImage
                case let .loaded(avatar):
                    self.state = .image(url: avatar.avatarUrl)
                case let .error(message):
                    self.state = .error(message)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    func send(_ event: MainViewEvents) async {
        switch event {
        case .load:
            state = .loadingImage
            await emojiRandomViewModel.send(.loadRandomEmoji)
        case .showEmojis:
            appRouter.push(.emojiesList)
        case .fetchRandomEmoji:
            state = .loadingImage
            await emojiRandomViewModel.send(.loadRandomEmoji)
        case .showAvatars:
            appRouter.push(.avatarsList)
        case let .search(username):
            state = .loadingImage
            await avatarSearchViewModel.send(.search(username: username))
        }
    }
}
