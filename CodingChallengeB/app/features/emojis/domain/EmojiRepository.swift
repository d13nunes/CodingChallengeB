import Foundation
import SwiftData

enum EmojiRepositoryError: Error {
    case failed(reason: String)
}

extension EmojiRepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .failed(reason):
            return reason
        }
    }
}

protocol EmojiRepositoryProtocol {
    func fetch(useCache: Bool) async -> Result<[EmojiValue], EmojiRepositoryError>
    func fetchRandom() async -> Result<EmojiValue, EmojiRepositoryError>
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
            if useCache {
                let localEmojis = try await getCachedEmojis()
                if !localEmojis.isEmpty {
                    return .success(localEmojis)
                }
            }
            let remoteResult = await remoteSource.fetchAll()

            switch remoteResult {
            case let .failure(error):
                return .failure(EmojiRepositoryError.failed(reason: error.localizedDescription))
            case let .success(emojis):
                try localSource.delete(model: EmojiEntity.self)
                for emoji in emojis {
                    localSource.insert(EmojiEntity(name: emoji.name, urlString: emoji.url))
                }
                try localSource.save()
            }
            let localEmojis = try await getCachedEmojis()
            return .success(localEmojis)
        } catch {
            return .failure(EmojiRepositoryError.failed(reason: error.localizedDescription))
        }
    }

    private func getCachedEmojis(sortBy: [SortDescriptor<EmojiEntity>] = [SortDescriptor(\.name, order: .forward)]) async throws -> [EmojiValue] {
        let descriptor = FetchDescriptor<EmojiEntity>(sortBy: sortBy)
        let localEmojis: [EmojiEntity] = try localSource.fetch(descriptor)
        return localEmojis.map { $0.toValue() }
    }

    func fetchRandom() async -> Result<EmojiValue, EmojiRepositoryError> {
        let result = await fetch()
        switch result {
        case let .failure(error):
            return .failure(error)
        case let .success(emojis):
            guard let randomEmoji = emojis.randomElement() else {
                return .failure(EmojiRepositoryError.failed(reason: "No emoji found"))
            }
            return .success(randomEmoji)
        }
    }
}

extension EmojiEntity {
    func toValue() -> EmojiValue {
        return EmojiValue(id: id, name: name, url: URL(string: urlString))
    }
}

extension EmojiDTO {
    func toEntity() -> EmojiEntity {
        return EmojiEntity(name: name, urlString: url)
    }
}
