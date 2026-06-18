import Foundation
import SwiftData

@Model
final class AvatarEntity {
    @Attribute(.unique)
    var username: String
    var avatarUrl: String
    var searchedAt: Date

    init(username: String, avatarUrl: String, searchedAt: Date = Date()) {
        self.username = username
        self.avatarUrl = avatarUrl
        self.searchedAt = searchedAt
    }
}
