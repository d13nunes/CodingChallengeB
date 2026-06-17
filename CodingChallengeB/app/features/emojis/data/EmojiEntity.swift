import Foundation
import SwiftData

@Model
final class EmojiEntity {
    var name: String
    @Attribute(.unique) // @urlString is what distinguishes emojis from each other because of that is marked has unique
    var urlString: String

    init(name: String, urlString: String) {
        self.name = name
        self.urlString = urlString
    }
}
