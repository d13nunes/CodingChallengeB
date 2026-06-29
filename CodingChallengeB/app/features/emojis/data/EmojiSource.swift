import Combine
import Foundation
import SwiftData

protocol EmojiSourceProtocol {
    var subject: CurrentValueSubject<[EmojiValue], Never> { get }

    func get() async throws -> [EmojiValue]
    func insert(_ entity: [EmojiDTO]) async throws
    func deleteAll() async throws
}

@ModelActor
actor EmojiSource: EmojiSourceProtocol {
    nonisolated let subject: CurrentValueSubject<[EmojiValue], Never> = CurrentValueSubject([])

    func get() throws -> [EmojiValue] {
        let descriptor = FetchDescriptor<EmojiEntity>(sortBy: [SortDescriptor(\.name)])
        let localEmojis: [EmojiEntity] = try modelContext.fetch(descriptor)
        return localEmojis.map { $0.toValue() }
    }

    func insert(_ DTOs: [EmojiDTO]) async throws {
        try modelContext.delete(model: EmojiEntity.self)
        for emoji in DTOs {
            modelContext.insert(EmojiEntity(name: emoji.name, urlString: emoji.url))
        }
        try modelContext.save()
        let emojis = try get()
        subject.send(emojis)
    }

    func deleteAll() throws {
        try modelContext.delete(model: EmojiEntity.self)
        try modelContext.save()
    }
}

extension EmojiEntity {
    func toValue() -> EmojiValue {
        return EmojiValue(id: id, name: name, url: URL(string: urlString))
    }
}
