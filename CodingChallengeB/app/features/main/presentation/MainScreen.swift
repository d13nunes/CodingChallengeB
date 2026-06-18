import SwiftUI
import SwiftData

struct MainScreen: View {
    @StateObject private var viewModel: MainViewModel
    init(viewModel: MainViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
          VStack {
              switch viewModel.state {
              case .initial:
                  EmptyView()
              case let .image(url):
                  CachedAsyncImage(url: url) {
                      $0.resizable()
                          .aspectRatio(contentMode: .fit)
                  } placeholder: {
                      ProgressView().redacted(reason: .placeholder)
                  } error: {
                      Text("Error")
                  }
                  .frame(width: 120, height: 120)
                
              case let .error(error):
                  Text("Error: \(error)")
              case .loadingImage:
                ProgressView()
            }
            Button("Random Emoji") {
                fetchRandomEmoji()
            }
            .disabled(viewModel.state == .loadingImage)
            Button("Show All Emojis") {
                Task { @MainActor in
                  await viewModel.send(.showEmojis)
                }
            }
          }.task {
            if viewModel.state == .initial {
                await viewModel.send(.load)
            }
          }
    }

    private func fetchRandomEmoji(){
      Task { @MainActor in
        await viewModel.send(.fetchRandomEmoji)
      }
    }
}

#Preview {
  let schema = Schema([EmojiEntity.self])
  let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
  let repository = EmojiRepository(remoteSource: EmojisAPI(session: URLSession.shared), localSource: container.mainContext)
  let emojiViewModel = EmojiRandomViewModel(repository: repository)
  let router = AppRouter()
  let vm = MainViewModel(emojiRandomViewModel: emojiViewModel, appRouter: router)
  
  MainScreen(viewModel: vm)
    .modelContainer(container)
    
}
