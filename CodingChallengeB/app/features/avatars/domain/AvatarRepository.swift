import Foundation
import SwiftData

enum AvatarRepositoryError: Error {
    case failed(reason: String)
}

protocol AvatarRepositoryProtocol {
    func searchUser(username: String) async -> Result<AvatarValue, AvatarRepositoryError>
    func fetchHistory() async -> Result<[AvatarValue], AvatarRepositoryError>
}

@MainActor
class AvatarRepository: AvatarRepositoryProtocol {
    private let remoteSource: AvatarsAPIProtocol
    private let localSource: ModelContext

    init(remoteSource: AvatarsAPIProtocol, localSource: ModelContext) {
        self.remoteSource = remoteSource
        self.localSource = localSource
    }

    func searchUser(username: String) async -> Result<AvatarValue, AvatarRepositoryError> {
        do {
            if let cached = try findCached(username: username) {
                return .success(cached)
            }
            let remoteResult = await remoteSource.fetchUser(username: username)
            switch remoteResult {
            case let .failure(error):
                return .failure(.failed(reason: error.localizedDescription))
            case let .success(dto):
                try upsert(dto: dto)
            }
            guard let saved = try findCached(username: username) else {
                return .failure(.failed(reason: "Failed to retrieve saved entity"))
            }
            return .success(saved)
        } catch {
            return .failure(.failed(reason: error.localizedDescription))
        }
    }

    func fetchHistory() async -> Result<[AvatarValue], AvatarRepositoryError> {
        do {
            let descriptor = FetchDescriptor<AvatarEntity>(
                sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
            )
            let entities = try localSource.fetch(descriptor)
            return .success(entities.map { $0.toValue() })
        } catch {
            return .failure(.failed(reason: error.localizedDescription))
        }
    }

    private func findCached(username: String) throws -> AvatarValue? {
        let lowered = username.lowercased()
        let descriptor = FetchDescriptor<AvatarEntity>(
            predicate: #Predicate { $0.username == lowered }
        )
        return try localSource.fetch(descriptor).first?.toValue()
    }

    private func upsert(dto: AvatarDTO) throws {
        let lowered = dto.login.lowercased()
        let descriptor = FetchDescriptor<AvatarEntity>(
            predicate: #Predicate { $0.username == lowered }
        )
        if let existing = try localSource.fetch(descriptor).first {
            existing.avatarUrl = dto.avatarUrl
            existing.searchedAt = Date()
        } else {
            localSource.insert(AvatarEntity(username: lowered, avatarUrl: dto.avatarUrl))
        }
        try localSource.save()
    }
}

extension AvatarEntity {
    func toValue() -> AvatarValue {
        AvatarValue(id: username, username: username, avatarUrl: URL(string: avatarUrl), searchedAt: searchedAt)
    }
}
