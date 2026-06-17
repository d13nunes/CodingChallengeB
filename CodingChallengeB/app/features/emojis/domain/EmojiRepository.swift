import Foundation
import SwiftData

enum EmojiRepositoryError: Error {
    case failed(reason: String)
}

protocol EmojiRepositoryProtocol {
    func fetch(useCache: Bool) async -> Result<[EmojiValue], EmojiRepositoryError>
    
}

@MainActor
class EmojiRepository: EmojiRepositoryProtocol {
    private let remoteSource: EmojisAPIProtocol
    private let localSource: ModelContext

    init(remoteSource: EmojisAPIProtocol, localSource: ModelContext) {
        self.remoteSource = remoteSource
        self.localSource = localSource
    }

    func fetch(useCache: Bool = true) async -> Result<[EmojiValue], EmojiRepositoryError> {
        do {
            let sortBy: [SortDescriptor<EmojiEntity>] = [SortDescriptor(\.name, order: .forward)]
            if useCache {
                let descriptor = FetchDescriptor<EmojiEntity>(sortBy: sortBy)
                let localEmojis: [EmojiEntity] = try localSource.fetch(descriptor)
                if !localEmojis.isEmpty {
                    return .success(localEmojis.map { $0.toValue() })
                }
            }
            let remoteResult = await remoteSource.fetchAll()

            switch remoteResult {
            case let .failure(error):
                return .failure(EmojiRepositoryError.failed(reason: error.localizedDescription))
            case let .success(emojis):
                for emoji in emojis {
                    let domainEmoji = EmojiEntity(name: emoji.name, urlString: emoji.url)
                    localSource.insert(domainEmoji)
                }
                try localSource.save()
            }
            let descriptor = FetchDescriptor<EmojiEntity>(sortBy: sortBy)
            let localEmojis: [EmojiEntity] = try localSource.fetch(descriptor)
            return .success(localEmojis.map { $0.toValue() })
        } catch {
            return .failure(EmojiRepositoryError.failed(reason: error.localizedDescription))
        }
    }

}

extension EmojiEntity {
    func toValue() -> EmojiValue {
        return EmojiValue(name: name, url: URL(string: urlString))
    }
}
