import SwiftData
import SwiftUI

@main
struct CodingChallengeBApp: App {
    let sharedModelContainer: ModelContainer
    @State private var router: AppRouter
    @State private var mainViewModel: MainViewModel

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
        router = appRouter
        mainViewModel = MainViewModel(
            emojiRepository: EmojiRepository(
                remoteSource: EmojisAPI(session: URLSession.shared),
                localSource: container.mainContext
            ),
            avatarRepository: AvatarRepository(
                remoteSource: AvatarsAPI(session: URLSession.shared),
                localSource: container.mainContext
            ),
            appRouter: appRouter
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navigationPath) {
                MainScreen(viewModel: mainViewModel)
                    .navigationDestination(for: Route.self) { route in
                        let context = sharedModelContainer.mainContext
                        switch route {
                        case .main:
                            MainScreen(viewModel: mainViewModel)
                        case .emojiesList:
                            let emojiRepo = EmojiRepository(
                                remoteSource: EmojisAPI(session: URLSession.shared),
                                localSource: context
                            )
                            EmojisGridView(viewModel: EmojisViewModel(repository: emojiRepo))
                                .navigationTitle("Emojies")
                        case .avatarsList:
                            let avatarRepo = AvatarRepository(
                                remoteSource: AvatarsAPI(session: URLSession.shared),
                                localSource: context
                            )
                            AvatarsScreen(
                                historyViewModel: AvatarHistoryViewModel(repository: avatarRepo)
                            )
                            .navigationTitle("Avatars")
                        case .appleRepos:
                            AppleReposView(
                                viewModel: AppleReposViewModel(
                                    repository: AppleRepoRepository(api: AppleReposApi(session: URLSession.shared))
                                )
                            )
                        }
                    }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}
