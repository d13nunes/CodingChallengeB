import SwiftData
import SwiftUI

@main
struct CodingChallengeBApp: App {
    let sharedModelContainer: ModelContainer
    @StateObject private var router: AppRouter
    @StateObject private var mainViewModel: MainViewModel

    init() {
        let schema = Schema([EmojiEntity.self, AvatarEntity.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        sharedModelContainer = container

        let appRouter = AppRouter()
        let emojiRepo = EmojiRepository(
            remoteSource: EmojisAPI(session: URLSession.shared),
            localSource: container.mainContext
        )
        let avatarRepo = AvatarRepository(
            remoteSource: AvatarsAPI(session: URLSession.shared),
            localSource: container.mainContext
        )
        let emojiVM = EmojiRandomViewModel(repository: emojiRepo)
        let avatarSearchVM = AvatarSearchViewModel(repository: avatarRepo)

        _router = StateObject(wrappedValue: appRouter)
        _mainViewModel = StateObject(wrappedValue: MainViewModel(
            emojiRandomViewModel: emojiVM,
            avatarSearchViewModel: avatarSearchVM,
            appRouter: appRouter
        ))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navigationPath) {
                MainScreen(viewModel: mainViewModel)
                    .navigationDestination(for: Route.self) { route in
                        let emojiRepo = EmojiRepository(
                            remoteSource: EmojisAPI(session: URLSession.shared),
                            localSource: sharedModelContainer.mainContext
                        )
                        switch route {
                        case .main:
                            let avatarRepo = AvatarRepository(
                                remoteSource: AvatarsAPI(session: URLSession.shared),
                                localSource: sharedModelContainer.mainContext
                            )
                            MainScreen(viewModel: MainViewModel(
                                emojiRandomViewModel: EmojiRandomViewModel(repository: emojiRepo),
                                avatarSearchViewModel: AvatarSearchViewModel(repository: avatarRepo),
                                appRouter: router
                            ))
                        case .emojiesList:
                            EmojisGridView(viewModel: EmojisViewModel(repository: emojiRepo))
                                .navigationTitle("Emojies")
                        case .avatarsList:
                            let avatarRepo = AvatarRepository(
                                remoteSource: AvatarsAPI(session: URLSession.shared),
                                localSource: sharedModelContainer.mainContext
                            )
                            AvatarsScreen(
                                historyViewModel: AvatarHistoryViewModel(repository: avatarRepo)
                            )
                            .navigationTitle("Avatars")
                        }
                    }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}
