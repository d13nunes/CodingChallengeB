import Foundation
import SwiftData

protocol AvatarSourceProtocol {
    func find(username: String) async throws -> AvatarValue?
    func history() async throws -> [AvatarValue]
    func upsert(_ dto: AvatarDTO) async throws
    func delete(username: String) async throws
}

@ModelActor
actor AvatarSource: AvatarSourceProtocol {
    func find(username: String) throws -> AvatarValue? {
        let lowered = username.lowercased()
        let descriptor = FetchDescriptor<AvatarEntity>(
            predicate: #Predicate { $0.username == lowered }
        )
        return try modelContext.fetch(descriptor).first?.toValue()
    }

    func history() throws -> [AvatarValue] {
        let descriptor = FetchDescriptor<AvatarEntity>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toValue() }
    }

    func upsert(_ dto: AvatarDTO) throws {
        let lowered = dto.login.lowercased()
        let descriptor = FetchDescriptor<AvatarEntity>(
            predicate: #Predicate { $0.username == lowered }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.avatarUrl = dto.avatarUrl
            existing.searchedAt = Date()
        } else {
            modelContext.insert(AvatarEntity(username: lowered, avatarUrl: dto.avatarUrl))
        }
        try modelContext.save()
    }

    func delete(username: String) throws {
        let lowered = username.lowercased()
        let descriptor = FetchDescriptor<AvatarEntity>(
            predicate: #Predicate { $0.username == lowered }
        )
        if let entity = try modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }
}

extension AvatarEntity {
    func toValue() -> AvatarValue {
        AvatarValue(id: username, username: username, avatarUrl: URL(string: avatarUrl), searchedAt: searchedAt)
    }
}
