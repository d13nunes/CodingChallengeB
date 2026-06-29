import Combine
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

class EmojiRepository: EmojiRepositoryProtocol {
    private let remoteSource: EmojisAPIProtocol
    private let source: EmojiSourceProtocol

    init(remoteSource: EmojisAPIProtocol, localSource: ModelContext) {
        self.remoteSource = remoteSource
        source = EmojiSource(modelContainer: localSource.container)
    }

    func fetch(useCache: Bool = true) async -> Result<[EmojiValue], EmojiRepositoryError> {
        do {
            if useCache {
                let localEmojis = try await source.get()
                if !localEmojis.isEmpty {
                    return .success(localEmojis)
                }
            }
            let remoteResult = await remoteSource.fetchAll()

            switch remoteResult {
            case let .failure(error):
                return .failure(EmojiRepositoryError.failed(reason: error.localizedDescription))
            case let .success(emojis):
                do {
                    try await source.insert(emojis)

                } catch {
                    print(error)
                }
            }
            let localEmojis = try await source.get()
            return .success(localEmojis)
        } catch {
            return .failure(EmojiRepositoryError.failed(reason: error.localizedDescription))
        }
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

extension EmojiDTO {
    func toEntity() -> EmojiEntity {
        return EmojiEntity(name: name, urlString: url)
    }
}
