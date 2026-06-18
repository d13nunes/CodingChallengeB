import SwiftData
import SwiftUI

@main
struct CodingChallengeBApp: App {
    let sharedModelContainer: ModelContainer
    @StateObject private var router: AppRouter
    @StateObject private var mainViewModel: MainViewModel

    init() {
        let schema = Schema([EmojiEntity.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        sharedModelContainer = container

        let appRouter = AppRouter()
        let repository = EmojiRepository(
            remoteSource: EmojisAPI(session: URLSession.shared),
            localSource: container.mainContext
        )
        let emojiVM = EmojiRandomViewModel(repository: repository)

        _router = StateObject(wrappedValue: appRouter)
        _mainViewModel = StateObject(wrappedValue: MainViewModel(emojiRandomViewModel: emojiVM, appRouter: appRouter))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navigationPath) {
                MainScreen(viewModel: mainViewModel)
                    .navigationDestination(for: Route.self) { route in
                        let repository = EmojiRepository(
                            remoteSource: EmojisAPI(session: URLSession.shared),
                            localSource: sharedModelContainer.mainContext
                        )
                        switch route {
                        case .main:
                            MainScreen(viewModel: MainViewModel(
                                emojiRandomViewModel: EmojiRandomViewModel(repository: repository),
                                appRouter: router
                            ))
                        case .emojiesList:
                          EmojisGridView(viewModel: EmojisViewModel(repository: repository))
                            .navigationTitle("Emojies")
                        }
                    }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}
