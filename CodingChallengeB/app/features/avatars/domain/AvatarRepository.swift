import Foundation
import SwiftData

enum AvatarRepositoryError: Error {
    case failed(reason: String)
}

extension AvatarRepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .failed(reason):
            return reason
        }
    }
}

protocol AvatarRepositoryProtocol {
    func searchUser(username: String) async -> Result<AvatarValue, AvatarRepositoryError>
    func fetchHistory() async -> Result<[AvatarValue], AvatarRepositoryError>
    func delete(username: String) async -> Result<Void, AvatarRepositoryError>
}

class AvatarRepository: AvatarRepositoryProtocol {
    private let remoteSource: AvatarsAPIProtocol
    private let source: AvatarSourceProtocol

    init(remoteSource: AvatarsAPIProtocol, localSource: ModelContext) {
        self.remoteSource = remoteSource
        source = AvatarSource(modelContainer: localSource.container)
    }

    func searchUser(username: String) async -> Result<AvatarValue, AvatarRepositoryError> {
        do {
            if let cached = try await source.find(username: username) {
                return .success(cached)
            }
            let remoteResult = await remoteSource.fetchUser(username: username)
            switch remoteResult {
            case let .failure(error):
                return .failure(.failed(reason: error.localizedDescription))
            case let .success(dto):
                try await source.upsert(dto)
            }
            guard let saved = try await source.find(username: username) else {
                return .failure(.failed(reason: "Failed to retrieve saved entity"))
            }
            return .success(saved)
        } catch {
            return .failure(.failed(reason: error.localizedDescription))
        }
    }

    func fetchHistory() async -> Result<[AvatarValue], AvatarRepositoryError> {
        do {
            let history = try await source.history()
            return .success(history)
        } catch {
            return .failure(.failed(reason: error.localizedDescription))
        }
    }

    func delete(username: String) async -> Result<Void, AvatarRepositoryError> {
        do {
            try await source.delete(username: username)
            return .success(())
        } catch {
            return .failure(.failed(reason: error.localizedDescription))
        }
    }
}
